package fun.hykgraph.controller.user;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.entity.FlightAnnouncement;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.entity.User;
import fun.hykgraph.entity.UserPreference;
import fun.hykgraph.mapper.DishMapper;
import fun.hykgraph.mapper.FlightAnnouncementMapper;
import fun.hykgraph.mapper.FlightInfoMapper;
import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.mapper.UserMapper;
import fun.hykgraph.mapper.UserPreferenceMapper;
import fun.hykgraph.result.Result;
import fun.hykgraph.vo.PendingRatingInfoVO;
import fun.hykgraph.vo.RecommendationDishVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@RestController("userRecommendationController")
@RequestMapping("/user")
@Slf4j
public class RecommendationController {

    private static final Set<Integer> ALLOWED_MEAL_TYPES = new HashSet<>(Arrays.asList(1, 2, 3, 4));
    private static final int MANUAL_SELECTION_CONFIRMED_STATUS = 3;
    private static final Set<String> ALLOWED_FLAVORS = new HashSet<>(Arrays.asList("清淡", "咸香", "微辣", "甜口", "低脂", "高蛋白"));
    private static final String FUSED_ALGORITHM_TYPE = "fused-pmfup-prmidm-ammbc-v1";
    private static final String RATING_STATUS_PENDING = "PENDING";
    private static final long RATING_EXPIRE_DAYS = 7;
    private static final long RATING_DEFER_HOURS = 24;
    private static final int DEFAULT_MEAL_ORDER = 1;
    private static final List<String> BREAKFAST_KEYWORDS = Arrays.asList("粥", "包", "馒头", "豆浆", "油条", "面", "面包", "三明治", "吐司", "蛋");

    @Autowired
    private UserMapper userMapper;
    @Autowired
    private FlightInfoMapper flightInfoMapper;
    @Autowired
    private FlightAnnouncementMapper announcementMapper;
    @Autowired
    private UserPreferenceMapper userPreferenceMapper;
    @Autowired
    private RecommendationMapper recommendationMapper;
    @Autowired
    private DishMapper dishMapper;

    @GetMapping("/flight/current")
    public Result<FlightInfo> currentFlight() {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        if (user == null || user.getCurrentFlightId() == null) {
            return Result.success(null);
        }
        return Result.success(flightInfoMapper.getById(user.getCurrentFlightId()));
    }

    @PostMapping("/flight/bind")
    public Result bindFlight(@RequestBody Map<String, Integer> params) {
        Integer userId = BaseContext.getCurrentId();
        Integer flightId = params.get("flightId");
        if (flightId == null) {
            return Result.error("flightId不能为空");
        }
        FlightInfo flightInfo = flightInfoMapper.getById(flightId);
        if (flightInfo == null) {
            return Result.error("航班不存在");
        }
        userMapper.bindFlight(userId, flightId);
        return Result.success();
    }

    @GetMapping("/flight/list")
    public Result<List<FlightInfo>> flightList(@RequestParam(required = false) String idNumber) {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        String queryIdNumber = idNumber;
        if ((queryIdNumber == null || queryIdNumber.trim().isEmpty()) && user != null) {
            queryIdNumber = user.getIdNumber();
        }
        if (queryIdNumber == null || queryIdNumber.trim().isEmpty()) {
            return Result.success(new ArrayList<>());
        }
        return Result.success(userMapper.listFlightsByIdNumber(queryIdNumber.trim()));
    }

    @GetMapping("/preference")
    public Result<UserPreference> getPreference() {
        Integer userId = BaseContext.getCurrentId();
        return Result.success(userPreferenceMapper.getByUserId(userId));
    }

    @PutMapping("/preference")
    public Result savePreference(@RequestBody UserPreference preference) {
        Integer userId = BaseContext.getCurrentId();
        String validation = validatePreference(preference);
        if (validation != null) {
            return Result.error(validation);
        }
        preference.setUserId(userId);
        preference.setUpdateTime(LocalDateTime.now());
        UserPreference db = userPreferenceMapper.getByUserId(userId);
        if (db == null) {
            preference.setCreateTime(LocalDateTime.now());
            userPreferenceMapper.insert(preference);
        } else {
            userPreferenceMapper.update(preference);
        }
        int completed = parseFlavorList(preference.getFlavorPreferences()).isEmpty() ? 0 : 1;
        userMapper.updatePreferenceCompleted(userId, completed);
        return Result.success();
    }

    @GetMapping("/recommendation/list")
    public Result<List<RecommendationDishVO>> list(@RequestParam(required = false) String mealType,
                                                   @RequestParam(required = false) String flavor,
                                                   @RequestParam(required = false) Integer mealOrder,
                                                   @RequestParam(defaultValue = "10") Integer size) {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        Integer flightId = user != null ? user.getCurrentFlightId() : null;
        if (flightId == null) {
            return Result.error("请先绑定航班");
        }
        FlightInfo flightInfo = flightId == null ? null : flightInfoMapper.getById(flightId);
        int safeMealOrder = resolveMealOrder(mealOrder, flightInfo == null ? null : flightInfo.getMealCount());
        Integer mealTypeParam = parseMealType(mealType);
        String flavorParam = normalizeParam(flavor);
        if (mealTypeParam != null && !ALLOWED_MEAL_TYPES.contains(mealTypeParam)) {
            return Result.error("mealType不在允许范围");
        }
        if (flavorParam != null && !ALLOWED_FLAVORS.contains(flavorParam)) {
            return Result.error("flavor不在允许范围");
        }
        List<RecommendationDishVO> list = recommendationMapper.listCandidateDishes(flightId, mealTypeParam, flavorParam, Math.min(size, 20));
        if (list.isEmpty()) {
            return Result.success(list);
        }

        List<Map<String, Object>> recentLogs = recommendationMapper.listRecentLogs(180);
        UserPreference preference = userPreferenceMapper.getByUserId(userId);
        Integer prefMealType = parsePreferenceMealType(preference == null ? null : preference.getMealTypePreferences());
        Set<String> prefFlavors = new HashSet<>(parseFlavorList(preference == null ? null : preference.getFlavorPreferences()));

        Map<Integer, RecommendationDishVO> candidateMap = list.stream()
                .filter(item -> item.getDishId() != null)
                .collect(Collectors.toMap(RecommendationDishVO::getDishId, item -> item, (a, b) -> a));
        Map<String, Integer> dishNameIdMap = list.stream()
                .filter(item -> item.getDishId() != null && item.getDishName() != null)
                .collect(Collectors.toMap(item -> item.getDishName().trim(), RecommendationDishVO::getDishId, (a, b) -> a));

        InteractionContext context = buildInteractionContext(recentLogs, candidateMap, dishNameIdMap);
        int idx = 0;
        for (RecommendationDishVO item : list) {
            double pmfupScore = calculatePmfupScore(item, prefMealType, prefFlavors, flightId, context, userId,
                    flightInfo == null ? null : flightInfo.getDepartureTime(), safeMealOrder);
            double prmidmScore = calculatePrmidmScore(userId, item.getDishId(), context);
            double ammbcScore = calculateAmmbcScore(userId, item.getDishId(), context);

            double fusedScore = 0.45 * pmfupScore + 0.30 * prmidmScore + 0.25 * ammbcScore;

            List<String> reasons = new ArrayList<>();
            if (pmfupScore >= 0.65) reasons.add("多源偏好融合");
            if (prmidmScore >= 0.55) reasons.add("兴趣漂移感知");
            if (ammbcScore >= 0.50) reasons.add("双向主动匹配");
            if (reasons.isEmpty()) reasons.add("基础稳健推荐");

            item.setFallbackLevel(idx++);
            item.setExplainReason(String.join(" + ", reasons));
            item.setScore(Math.min(1.0, Math.max(0.0, fusedScore)));
        }

        list.sort((a, b) -> Double.compare(b.getScore(), a.getScore()));
        for (int i = 0; i < list.size(); i++) {
            RecommendationDishVO item = list.get(i);
            if (item.getFallbackLevel() == null) {
                item.setFallbackLevel(i);
            }
            if (item.getExplainReason() == null || item.getExplainReason().trim().isEmpty()) {
                item.setExplainReason("基础营养均衡推荐");
            }
        }

        Map<String, Object> recommendLog = new HashMap<>();
        recommendLog.put("userId", userId);
        recommendLog.put("flightId", flightId);
        recommendLog.put("recommendedDishes", list.stream().map(RecommendationDishVO::getDishId).toList().toString());
        recommendLog.put("algorithmType", resolveAlgorithmType(userId));
        recommendLog.put("userFeedback", "");
        try {
            recommendationMapper.insertLog(recommendLog);
        } catch (Exception ex) {
            log.warn("推荐日志写入失败，已跳过。userId={}, flightId={}", userId, flightId, ex);
        }

        return Result.success(list);
    }

    private Integer parseMealType(String mealType) {
        String value = normalizeParam(mealType);
        if (value == null) {
            return null;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String normalizeParam(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty() || "undefined".equalsIgnoreCase(trimmed) || "null".equalsIgnoreCase(trimmed)) {
            return null;
        }
        return trimmed;
    }

    @GetMapping("/recommendation/history")
    public Result<List<Map<String, Object>>> history() {
        Integer userId = BaseContext.getCurrentId();
        return Result.success(recommendationMapper.listHistory(userId));
    }

    @GetMapping("/recommendation/pending-rating")
    public Result<List<PendingRatingInfoVO>> pendingRating() {
        Integer userId = BaseContext.getCurrentId();
        List<PendingRatingInfoVO> pendingList = resolvePendingRatings(userId, LocalDateTime.now());
        if (pendingList == null || pendingList.isEmpty()) {
            return Result.success(new ArrayList<>());
        }
        for (PendingRatingInfoVO item : pendingList) {
            item.setDishId(extractDishIdFromText(item.getRecommendedDishes()));
        }
        return Result.success(pendingList);
    }

    @GetMapping("/recommendation/top")
    public Result<List<Map<String, Object>>> top(@RequestParam(defaultValue = "5") Integer size) {
        return Result.success(recommendationMapper.topDishes(Math.min(size, 10), null, null));
    }

    @PostMapping("/recommendation/select")
    @Transactional(rollbackFor = Exception.class)
    public Result<Map<String, Object>> selectMeal(@RequestBody Map<String, Integer> params) {
        Integer dishId = params.get("dishId");
        if (dishId == null) {
            return Result.error("dishId不能为空");
        }
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        if (user == null || user.getCurrentFlightId() == null) {
            return Result.error("请先绑定航班");
        }
        FlightInfo flightInfo = flightInfoMapper.getById(user.getCurrentFlightId());
        if (flightInfo == null) {
            return Result.error("航班不存在");
        }
        if (flightInfo.getSelectionDeadline() != null && LocalDateTime.now().isAfter(flightInfo.getSelectionDeadline())) {
            return Result.error("该航班预选已截止，系统将自动分配餐食");
        }
        int safeMealOrder = resolveMealOrder(params.get("mealOrder"), flightInfo.getMealCount());
        Integer existed = recommendationMapper.existsMealSelection(userId, flightInfo.getId(), safeMealOrder);
        LocalDateTime now = LocalDateTime.now();
        boolean modified = existed != null && existed > 0;

        Integer previousDishId = null;
        if (modified) {
            Map<String, Object> latest = recommendationMapper.latestManualSelection(userId, flightInfo.getId(), safeMealOrder);
            previousDishId = extractDishIdFromLatestSelection(latest);
            if (previousDishId != null && Objects.equals(previousDishId, dishId)) {
                recommendationMapper.updateMealSelectionStatusAndUpdateTime(userId, flightInfo.getId(), safeMealOrder, MANUAL_SELECTION_CONFIRMED_STATUS, now);
                Map<String, Object> response = new HashMap<>();
                response.put("flightId", flightInfo.getId());
                response.put("dishId", dishId);
                response.put("mealOrder", safeMealOrder);
                response.put("selectedAt", now);
                response.put("modified", true);
                response.put("selectionDeadline", flightInfo.getSelectionDeadline());
                return Result.success(response);
            }
        }

        Integer affected = dishMapper.decreaseStockAndAutoDisable(dishId, 1);
        if (affected == null || affected == 0) {
            dishMapper.disableIfOutOfStock(dishId);
            return Result.error("该餐食库存不足，请重新选择");
        }

        if (modified) {
            if (previousDishId != null) {
                dishMapper.increaseStockAndEnable(previousDishId, 1);
            }
            recommendationMapper.updateMealSelectionStatusAndUpdateTime(userId, flightInfo.getId(), safeMealOrder, MANUAL_SELECTION_CONFIRMED_STATUS, now);
            insertManualSelectionLog(userId, flightInfo.getId(), dishId, safeMealOrder, "MANUAL_SELECTED_UPDATE");
        } else {
            Map<String, Object> selection = new HashMap<>();
            selection.put("number", "SEL" + System.currentTimeMillis() + userId);
            selection.put("status", MANUAL_SELECTION_CONFIRMED_STATUS);
            selection.put("userId", userId);
            selection.put("flightId", flightInfo.getId());
            selection.put("mealOrder", safeMealOrder);
            selection.put("seatNumber", "USER");
            selection.put("createTime", now);
            selection.put("updateTime", now);
            recommendationMapper.insertMealSelection(selection);
            insertManualSelectionLog(userId, flightInfo.getId(), dishId, safeMealOrder, "MANUAL_SELECTED");
        }

        Map<String, Object> response = new HashMap<>();
        response.put("flightId", flightInfo.getId());
        response.put("dishId", dishId);
        response.put("mealOrder", safeMealOrder);
        response.put("selectedAt", now);
        response.put("modified", modified);
        response.put("selectionDeadline", flightInfo.getSelectionDeadline());
        return Result.success(response);
    }

    @PostMapping("/recommendation/rate")
    @Transactional(rollbackFor = Exception.class)
    public Result rateRecommendation(@RequestBody Map<String, Integer> params) {
        Integer rating = params.get("rating");
        if (rating == null || rating < 1 || rating > 5) {
            return Result.error("评分范围必须为1-5星");
        }

        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        Integer flightId = params.get("flightId");
        if (flightId == null) {
            flightId = user != null ? user.getCurrentFlightId() : null;
        }
        if (flightId == null) {
            return Result.error("请先选择航班");
        }

        LocalDateTime now = LocalDateTime.now();
        Integer affected = recommendationMapper.submitFlightRating(userId, flightId, rating, now);
        if (affected == null || affected <= 0) {
            // If task row is not materialized yet, try seeding once from ended manual selection.
            resolvePendingRatings(userId, now);
            affected = recommendationMapper.submitFlightRating(userId, flightId, rating, now);
            if (affected == null || affected <= 0) {
                return Result.error("当前没有可评分航班或评分已过期");
            }
        }

        recommendationMapper.syncSubmittedLogRating(userId, flightId, rating);
        recommendationMapper.updateLatestManualRating(userId, flightId, DEFAULT_MEAL_ORDER, rating);

        return Result.success();
    }

    @PostMapping("/recommendation/rate/defer")
    public Result deferRecommendation(@RequestBody(required = false) Map<String, Integer> params) {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        Integer flightId = params == null ? null : params.get("flightId");
        if (flightId == null) {
            flightId = user != null ? user.getCurrentFlightId() : null;
        }
        if (flightId == null) {
            return Result.error("请先选择航班");
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime nextRemindAt = now.plusHours(RATING_DEFER_HOURS);
        Integer affected = recommendationMapper.deferFlightRating(userId, flightId, nextRemindAt, now);
        if (affected == null || affected <= 0) {
            return Result.error("当前没有可延期评分的航班");
        }
        return Result.success();
    }

    @GetMapping("/profile/tags")
    public Result<List<String>> profileTags() {
        Integer userId = BaseContext.getCurrentId();
        List<Map<String, Object>> rows = recommendationMapper.preferenceTags(userId);
        List<String> tags = rows.stream()
                .map(row -> row.get("tag"))
                .filter(Objects::nonNull)
                .map(String::valueOf)
                .distinct()
                .collect(Collectors.toList());
        if (tags.isEmpty()) {
            tags.add("待完善偏好画像");
        }
        return Result.success(tags);
    }

    @GetMapping("/announcement/list")
    public Result<List<FlightAnnouncement>> announcementList() {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        Integer flightId = user != null ? user.getCurrentFlightId() : null;
        return Result.success(announcementMapper.list(flightId));
    }

    private String resolveAlgorithmType(Integer userId) {
        return FUSED_ALGORITHM_TYPE;
    }

    private double calculatePmfupScore(RecommendationDishVO item,
                                       Integer prefMealType,
                                       Set<String> prefFlavors,
                                       Integer flightId,
                                       InteractionContext context,
                                       Integer userId,
                                       LocalDateTime departureTime,
                                       Integer mealOrder) {
        if (item == null || item.getDishId() == null) {
            return 0.0;
        }

        double timeScore = calculateTimePreferenceScore(item, departureTime, mealOrder);
        double prefScore = 0.2;
        if (prefMealType != null && item.getMealType() != null && prefMealType.equals(item.getMealType())) {
            prefScore += 0.45;
        }
        if (!prefFlavors.isEmpty() && item.getFlavorTags() != null) {
            int matched = 0;
            for (String flavor : prefFlavors) {
                if (item.getFlavorTags().contains(flavor)) {
                    matched++;
                }
            }
            if (matched > 0) {
                prefScore += Math.min(0.35, 0.15 + matched * 0.10);
            }
        }
        double assocScore = calculateAssociationScore(userId, item.getDishId(), context);

        return clamp01(0.44 * prefScore + 0.26 * timeScore + 0.30 * assocScore);
    }

    private double calculatePrmidmScore(Integer userId, Integer dishId, InteractionContext context) {
        if (dishId == null || userId == null) {
            return 0.0;
        }
        double interest = context.userDishScore
                .getOrDefault(userId, Collections.emptyMap())
                .getOrDefault(dishId, 0.0);
        double revisitBoost = context.userDishRepeat
                .getOrDefault(userId, Collections.emptyMap())
                .getOrDefault(dishId, 0);

        double boosted = interest * (1.0 + Math.min(0.35, revisitBoost * 0.06));
        return clamp01(boosted / 8.0);
    }

    private double calculateAmmbcScore(Integer userId, Integer dishId, InteractionContext context) {
        if (dishId == null || userId == null) {
            return 0.0;
        }

        Map<Integer, Double> current = context.userDishScore.getOrDefault(userId, Collections.emptyMap());
        double simWeighted = 0.0;
        double simTotal = 0.0;
        for (Map.Entry<Integer, Map<Integer, Double>> entry : context.userDishScore.entrySet()) {
            Integer otherUserId = entry.getKey();
            if (Objects.equals(otherUserId, userId)) {
                continue;
            }
            Map<Integer, Double> otherVector = entry.getValue();
            if (!otherVector.containsKey(dishId)) {
                continue;
            }
            double sim = cosineSimilarity(current, otherVector);
            if (sim <= 0) {
                continue;
            }
            simWeighted += sim * otherVector.get(dishId);
            simTotal += sim;
        }
        double userToDish = simTotal > 0 ? clamp01((simWeighted / simTotal) / 8.0) : 0.0;

        double dishToUser = calculateAssociationScore(userId, dishId, context);
        return clamp01(0.62 * userToDish + 0.38 * dishToUser);
    }

    private double calculateAssociationScore(Integer userId, Integer targetDishId, InteractionContext context) {
        if (targetDishId == null || userId == null) {
            return 0.0;
        }
        Map<Integer, Double> userVector = context.userDishScore.getOrDefault(userId, Collections.emptyMap());
        if (userVector.isEmpty()) {
            return 0.0;
        }
        List<Map.Entry<Integer, Double>> topHist = userVector.entrySet().stream()
                .sorted((a, b) -> Double.compare(b.getValue(), a.getValue()))
                .limit(4)
                .toList();

        double score = 0.0;
        for (Map.Entry<Integer, Double> hist : topHist) {
            if (Objects.equals(hist.getKey(), targetDishId)) {
                continue;
            }
            String pair = buildPairKey(hist.getKey(), targetDishId);
            double assoc = context.pairAssociation.getOrDefault(pair, 0.0);
            score += assoc;
        }
        return clamp01(score / Math.max(1, topHist.size()));
    }

    private InteractionContext buildInteractionContext(List<Map<String, Object>> logs,
                                                       Map<Integer, RecommendationDishVO> candidateMap,
                                                       Map<String, Integer> dishNameIdMap) {
        InteractionContext ctx = new InteractionContext();
        for (Map<String, Object> row : logs) {
            Integer uid = parseInt(row.get("userId"));
            if (uid == null) {
                continue;
            }

            String feedback = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
            LocalDateTime createTime = parseDateTime(row.get("createTime"));
            double decay = timeDecay(createTime);

            Set<Integer> relatedDishIds = extractDishIds(row.get("recommendedDishes"), dishNameIdMap, candidateMap);
            for (Integer did : relatedDishIds) {
                addScore(ctx.userDishScore, uid, did, 1.0 * decay); // exposure
            }

            Integer selectedDishId = extractDishIdFromText(feedback);
            if (selectedDishId != null && candidateMap.containsKey(selectedDishId)) {
                if (feedback.startsWith("MANUAL_SELECTED")) {
                    addScore(ctx.userDishScore, uid, selectedDishId, 5.0 * decay);
                } else if (feedback.startsWith("AUTO_SELECTED_OVERDUE")) {
                    addScore(ctx.userDishScore, uid, selectedDishId, 3.0 * decay);
                } else if (feedback.startsWith("CLICK")) {
                    addScore(ctx.userDishScore, uid, selectedDishId, 2.0 * decay);
                }

                int repeated = ctx.userDishRepeat
                        .computeIfAbsent(uid, k -> new HashMap<>())
                        .getOrDefault(selectedDishId, 0);
                ctx.userDishRepeat.get(uid).put(selectedDishId, repeated + 1);
            }

            Integer rating = parseInt(row.get("userRating"));
            if (rating != null && rating > 0 && selectedDishId != null && candidateMap.containsKey(selectedDishId)) {
                addScore(ctx.userDishScore, uid, selectedDishId, (rating >= 4 ? 2.0 : 1.0) * decay); // click/interest signal
            }

            List<Integer> sorted = new ArrayList<>(relatedDishIds);
            for (int i = 0; i < sorted.size(); i++) {
                for (int j = i + 1; j < sorted.size(); j++) {
                    String key = buildPairKey(sorted.get(i), sorted.get(j));
                    ctx.pairAssociation.put(key, ctx.pairAssociation.getOrDefault(key, 0.0) + 0.12 * decay);
                }
            }
        }
        return ctx;
    }

    private double calculateTimePreferenceScore(Integer mealType) {
        return calculateTimePreferenceScore(mealType, LocalTime.now());
    }

    private double calculateTimePreferenceScore(RecommendationDishVO item, LocalDateTime departureTime, Integer mealOrder) {
        LocalTime referenceTime = resolveMealReferenceTime(departureTime, mealOrder);
        double mealTypeScore = calculateTimePreferenceScore(item == null ? null : item.getMealType(), referenceTime);
        if (item == null) {
            return mealTypeScore;
        }

        if (mealOrder != null && mealOrder == 1 && referenceTime.isBefore(LocalTime.of(10, 30))) {
            boolean breakfastSeries = isBreakfastSeriesDish(item.getDishName());
            if (breakfastSeries) {
                return clamp01(Math.max(mealTypeScore, 0.96));
            }
            return clamp01(mealTypeScore * 0.84);
        }
        return mealTypeScore;
    }

    private LocalTime resolveMealReferenceTime(LocalDateTime departureTime, Integer mealOrder) {
        LocalTime base = departureTime == null ? LocalTime.now() : departureTime.toLocalTime();
        int order = mealOrder == null || mealOrder < 1 ? 1 : mealOrder;
        return base.plusHours((long) (order - 1) * 4);
    }

    private boolean isBreakfastSeriesDish(String dishName) {
        if (dishName == null || dishName.trim().isEmpty()) {
            return false;
        }
        String name = dishName.trim();
        for (String keyword : BREAKFAST_KEYWORDS) {
            if (name.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private double calculateTimePreferenceScore(Integer mealType, LocalTime currentTime) {
        if (mealType == null || currentTime == null) {
            return 0.55;
        }

        LocalTime breakfastEnd = LocalTime.of(10, 30);
        LocalTime lunchEnd = LocalTime.of(15, 0);
        LocalTime dinnerEnd = LocalTime.of(21, 0);

        // Explicitly bias early time windows toward breakfast dishes.
        if (mealType == 1) {
            if (currentTime.isBefore(breakfastEnd)) {
                return 1.0;
            }
            if (currentTime.isBefore(lunchEnd)) {
                return 0.82;
            }
            if (currentTime.isBefore(dinnerEnd)) {
                return 0.64;
            }
            return 0.48;
        }

        if (currentTime.isBefore(breakfastEnd)) {
            return 0.52;
        }
        if (currentTime.isBefore(lunchEnd)) {
            return mealType == 2 ? 0.95 : 0.68;
        }
        if (currentTime.isBefore(dinnerEnd)) {
            return mealType == 3 ? 0.93 : 0.70;
        }
        return mealType == 4 ? 0.90 : 0.66;
    }

    private double timeDecay(LocalDateTime time) {
        if (time == null) {
            return 0.8;
        }
        long days = Math.max(0, ChronoUnit.DAYS.between(time, LocalDateTime.now()));
        return Math.exp(-0.018 * days);
    }

    private LocalDateTime parseDateTime(Object value) {
        if (value instanceof LocalDateTime localDateTime) {
            return localDateTime;
        }
        if (value == null) {
            return null;
        }
        try {
            return LocalDateTime.parse(String.valueOf(value).replace(" ", "T"));
        } catch (Exception ex) {
            return null;
        }
    }

    private void addScore(Map<Integer, Map<Integer, Double>> source, Integer userId, Integer dishId, double score) {
        source.computeIfAbsent(userId, k -> new HashMap<>())
                .put(dishId, source.get(userId).getOrDefault(dishId, 0.0) + score);
    }

    private Set<Integer> extractDishIds(Object value,
                                        Map<String, Integer> dishNameIdMap,
                                        Map<Integer, RecommendationDishVO> candidateMap) {
        Set<Integer> result = new HashSet<>();
        if (value == null) {
            return result;
        }
        String text = String.valueOf(value);
        for (Integer id : extractAllDishIds(text)) {
            if (candidateMap.containsKey(id)) {
                result.add(id);
            }
        }
        String compact = text.replace("[", "").replace("]", "").replace("\"", "");
        for (String token : compact.split(",")) {
            String key = token == null ? "" : token.trim();
            Integer id = dishNameIdMap.get(key);
            if (id != null) {
                result.add(id);
            }
        }
        return result;
    }

    private List<Integer> extractAllDishIds(String text) {
        List<Integer> ids = new ArrayList<>();
        if (text == null || text.isEmpty()) {
            return ids;
        }
        java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("dishId=(\\d+)|(?<!\\d)(\\d{1,6})(?!\\d)")
                .matcher(text);
        while (matcher.find()) {
            String num = matcher.group(1) != null ? matcher.group(1) : matcher.group(2);
            if (num == null) {
                continue;
            }
            try {
                ids.add(Integer.parseInt(num));
            } catch (Exception ignore) {
                // ignore invalid tokens
            }
        }
        return ids;
    }

    private String buildPairKey(Integer a, Integer b) {
        if (a == null || b == null) {
            return "0:0";
        }
        return a < b ? a + ":" + b : b + ":" + a;
    }

    private double cosineSimilarity(Map<Integer, Double> a, Map<Integer, Double> b) {
        if (a.isEmpty() || b.isEmpty()) {
            return 0.0;
        }
        double dot = 0.0;
        double normA = 0.0;
        double normB = 0.0;
        for (Map.Entry<Integer, Double> entry : a.entrySet()) {
            double av = entry.getValue() == null ? 0.0 : entry.getValue();
            double bv = b.getOrDefault(entry.getKey(), 0.0);
            dot += av * bv;
            normA += av * av;
        }
        for (Double v : b.values()) {
            double value = v == null ? 0.0 : v;
            normB += value * value;
        }
        if (normA <= 0 || normB <= 0) {
            return 0.0;
        }
        return dot / (Math.sqrt(normA) * Math.sqrt(normB));
    }

    private Integer parseInt(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }

    private Long parseLong(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }

    private double clamp01(double value) {
        if (value < 0) {
            return 0;
        }
        return Math.min(1, value);
    }

    private static class InteractionContext {
        private final Map<Integer, Map<Integer, Double>> userDishScore = new HashMap<>();
        private final Map<Integer, Map<Integer, Integer>> userDishRepeat = new HashMap<>();
        private final Map<String, Double> pairAssociation = new HashMap<>();
    }

    private String validatePreference(UserPreference preference) {
        if (preference == null) {
            return "偏好参数不能为空";
        }
        Integer mealType = parsePreferenceMealType(preference.getMealTypePreferences());
        if (mealType != null && !ALLOWED_MEAL_TYPES.contains(mealType)) {
            return "mealTypePreferences包含非法餐型";
        }
        List<String> flavors = parseFlavorList(preference.getFlavorPreferences());
        for (String item : flavors) {
            if (!ALLOWED_FLAVORS.contains(item)) {
                return "flavorPreferences包含非法口味:" + item;
            }
        }
        return null;
    }

    private Integer parsePreferenceMealType(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return null;
        }
        String compact = raw.replace("[", "").replace("]", "").replace("\"", "").trim();
        if (compact.isEmpty()) {
            return null;
        }
        String first = compact.split(",")[0].trim();
        try {
            return Integer.parseInt(first);
        } catch (Exception ex) {
            return null;
        }
    }

    private List<String> parseFlavorList(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return new ArrayList<>();
        }
        String compact = raw.replace("[", "").replace("]", "").replace("\"", "");
        String[] split = compact.split(",");
        List<String> result = new ArrayList<>();
        for (String item : split) {
            String trimmed = item == null ? "" : item.trim();
            if (!trimmed.isEmpty()) {
                result.add(trimmed);
            }
        }
        return result;
    }

    private void insertManualSelectionLog(Integer userId, Integer flightId, Integer dishId, Integer mealOrder, String event) {
        Map<String, Object> recommendLog = new HashMap<>();
        recommendLog.put("userId", userId);
        recommendLog.put("flightId", flightId);
        recommendLog.put("recommendedDishes", "[" + dishId + "]");
        recommendLog.put("algorithmType", resolveAlgorithmType(userId));
        recommendLog.put("userFeedback", event + ":dishId=" + dishId + ":mealOrder=" + mealOrder);
        recommendationMapper.insertLog(recommendLog);
    }

    private Integer extractDishIdFromLatestSelection(Map<String, Object> latest) {
        if (latest == null || latest.isEmpty()) {
            return null;
        }
        Integer fromFeedback = extractDishIdFromText(latest.get("userFeedback"));
        if (fromFeedback != null) {
            return fromFeedback;
        }
        return extractDishIdFromText(latest.get("recommendedDishes"));
    }

    private Integer extractDishIdFromText(Object value) {
        if (value == null) {
            return null;
        }
        String text = String.valueOf(value);
        java.util.regex.Matcher dishIdMatcher = java.util.regex.Pattern.compile("dishId=(\\d+)").matcher(text);
        String number = null;
        if (dishIdMatcher.find()) {
            number = dishIdMatcher.group(1);
        } else {
            java.util.regex.Matcher matcher = java.util.regex.Pattern
                    .compile("(?<!\\d)(\\d{1,6})(?!\\d)")
                    .matcher(text);
            if (matcher.find()) {
                number = matcher.group(1);
            }
        }
        if (number == null || number.isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(number);
        } catch (Exception ex) {
            return null;
        }
    }

    private List<PendingRatingInfoVO> resolvePendingRatings(Integer userId, LocalDateTime now) {
        List<PendingRatingInfoVO> pendingList = recommendationMapper.findVisiblePendingRatings(userId, now);
        List<Map<String, Object>> seeds = recommendationMapper.findEndedManualSelectionsWithoutRating(userId, now);
        if (seeds != null && !seeds.isEmpty()) {
            for (Map<String, Object> seed : seeds) {
                Integer flightId = parseInt(seed.get("flightId"));
                Long sourceLogId = parseLong(seed.get("sourceLogId"));
                if (flightId == null) {
                    continue;
                }

                Map<String, Object> params = new HashMap<>();
                params.put("userId", userId);
                params.put("flightId", flightId);
                params.put("sourceLogId", sourceLogId);
                params.put("ratingStatus", RATING_STATUS_PENDING);
                params.put("firstVisibleAt", now);
                params.put("lastVisibleAt", now);
                params.put("nextRemindAt", now);
                params.put("deferCount", 0);
                params.put("expireAt", now.plusDays(RATING_EXPIRE_DAYS));
                params.put("channel", "miniapp");
                params.put("createTime", now);
                params.put("updateTime", now);
                recommendationMapper.upsertFlightRatingTask(params);
            }
        }

        if (seeds == null || seeds.isEmpty()) {
            return pendingList == null ? new ArrayList<>() : pendingList;
        }
        return recommendationMapper.findVisiblePendingRatings(userId, now);
    }

    private int resolveMealOrder(Integer mealOrder, Integer mealCount) {
        int maxMealCount = (mealCount == null || mealCount <= 0) ? 1 : Math.min(mealCount, 3);
        if (mealOrder == null || mealOrder <= 0) {
            return 1;
        }
        return Math.min(mealOrder, maxMealCount);
    }
}
