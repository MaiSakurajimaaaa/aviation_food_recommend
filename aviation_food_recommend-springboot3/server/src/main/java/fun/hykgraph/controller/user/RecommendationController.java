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
import org.springframework.dao.DuplicateKeyException;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
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
    private static final String FUSED_ALGORITHM_TYPE = "fused-pmfup-prmidm-ammbc-v3";
    private static final double EXPOSURE_SCORE_WEIGHT = 0.15;
    private static final int RECENT_WINDOW_DAYS = 30;
    private static final int HISTORY_WINDOW_DAYS = 180;
    private static final double CF_SHRINK_LAMBDA = 3.0;
    private static final String RATING_STATUS_PENDING = "PENDING";
    private static final long RATING_EXPIRE_DAYS = 7;
    private static final long RATING_DEFER_HOURS = 24;
    private static final int CABIN_FIRST = 1;
    private static final int CABIN_BUSINESS = 2;
    private static final int CABIN_ECONOMY = 3;

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
        FlightInfo flightInfo = flightInfoMapper.getById(user.getCurrentFlightId());
        if (flightInfo != null && flightInfo.getArrivalTime() != null
                && flightInfo.getArrivalTime().isBefore(LocalDateTime.now())) {
            // 航班已结束，解绑用户
            userMapper.bindFlight(userId, null);
            return Result.success(null);
        }
        return Result.success(flightInfo);
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
        List<FlightInfo> flights = userMapper.listFlightsByIdNumber(queryIdNumber.trim());
        LocalDateTime now = LocalDateTime.now();
        flights.removeIf(f -> f.getArrivalTime() != null && f.getArrivalTime().isBefore(now));
        return Result.success(flights);
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
        FlightInfo flightInfo = flightInfoMapper.getById(flightId);
        int safeMealOrder = resolveMealOrder(mealOrder, flightInfo == null ? null : flightInfo.getMealCount());
        Integer mealTypeParam = parseMealType(mealType);
        String flavorParam = normalizeParam(flavor);
        if (mealTypeParam != null && !ALLOWED_MEAL_TYPES.contains(mealTypeParam)) {
            return Result.error("mealType不在允许范围");
        }
        if (flavorParam != null && !ALLOWED_FLAVORS.contains(flavorParam)) {
            return Result.error("flavor不在允许范围");
        }
        List<Integer> cabinTypes = resolveUserCabinTypes(user);
        List<RecommendationDishVO> list = recommendationMapper.listCandidateDishes(
                flightId,
                mealTypeParam,
                flavorParam,
                Math.min(size, 20),
            cabinTypes
        );
        if (list.isEmpty()) {
            return Result.success(list);
        }

        List<Map<String, Object>> recentLogs = recommendationMapper.listRecentLogs(HISTORY_WINDOW_DAYS, 5000);
        UserPreference preference = userPreferenceMapper.getByUserId(userId);
        Set<Integer> prefMealTypes = parsePreferenceMealTypes(preference == null ? null : preference.getMealTypePreferences());
        Set<String> prefFlavors = new HashSet<>(parseFlavorList(preference == null ? null : preference.getFlavorPreferences()));

        Map<Integer, RecommendationDishVO> candidateMap = list.stream()
                .filter(item -> item.getDishId() != null)
                .collect(Collectors.toMap(RecommendationDishVO::getDishId, item -> item, (a, b) -> a));
        Map<String, Integer> dishNameIdMap = list.stream()
                .filter(item -> item.getDishId() != null && item.getDishName() != null)
                .collect(Collectors.toMap(item -> item.getDishName().trim(), RecommendationDishVO::getDishId, (a, b) -> a));

        InteractionContext context = buildInteractionContext(recentLogs, candidateMap, dishNameIdMap);
        double[] fusionWeights = resolveFusionWeights(userId, context);
        int behaviorSignalCount = resolveBehaviorSignalCount(userId, context);
        Integer prevDishId = null;
        Integer prevMealType = null;
        if (safeMealOrder > 1) {
            Map<String, Object> prevSelection = recommendationMapper.latestManualSelection(userId, flightId, safeMealOrder - 1);
            prevDishId = extractDishIdFromLatestSelection(prevSelection);
            if (prevDishId != null) {
                RecommendationDishVO prevDish = candidateMap.get(prevDishId);
                if (prevDish != null) {
                    prevMealType = prevDish.getMealType();
                }
            }
        }
        int idx = 0;
        for (RecommendationDishVO item : list) {
            double pmfupScore = calculatePmfupScore(item, prefMealTypes, prefFlavors, flightId, context, userId,
                    flightInfo == null ? null : flightInfo.getDepartureTime(), safeMealOrder);
            double prmidmScore = calculatePrmidmScore(userId, item.getDishId(), context);
            double ammbcScore = calculateAmmbcScore(userId, item.getDishId(), context);

            double fusedScore = fusionWeights[0] * pmfupScore + fusionWeights[1] * prmidmScore + fusionWeights[2] * ammbcScore;
            if (prevDishId != null) {
                if (Objects.equals(item.getDishId(), prevDishId)) {
                    fusedScore *= 0.70;
                } else if (prevMealType != null && Objects.equals(item.getMealType(), prevMealType)) {
                    fusedScore *= 0.85;
                }
            }

            List<String> reasons = new ArrayList<>();
            if (pmfupScore >= 0.65) reasons.add("画像偏好匹配");
            if (prmidmScore >= 0.55) reasons.add("近期口味漂移");
            if (ammbcScore >= 0.40) reasons.add("协同过滤匹配");
            if (behaviorSignalCount < 3) reasons.add("行为样本不足");
            if (prevDishId != null && Objects.equals(item.getDishId(), prevDishId)) reasons.add("与前序餐食相同");
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

    private List<Integer> resolveUserCabinTypes(User user) {
        int cabinType = resolveUserCabinType(user == null ? null : user.getCabinType());
        if (cabinType == CABIN_FIRST) {
            return Arrays.asList(CABIN_FIRST, CABIN_BUSINESS, CABIN_ECONOMY);
        }
        if (cabinType == CABIN_BUSINESS) {
            return Arrays.asList(CABIN_BUSINESS, CABIN_ECONOMY);
        }
        return Collections.singletonList(CABIN_ECONOMY);
    }

    private int resolveUserCabinType(Integer cabinType) {
        if (cabinType == null) {
            return CABIN_ECONOMY;
        }
        if (cabinType >= CABIN_FIRST && cabinType <= CABIN_ECONOMY) {
            return cabinType;
        }
        return CABIN_ECONOMY;
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

    @PostMapping("/recommendation/click")
    public Result clickRecommendation(@RequestBody Map<String, Integer> params) {
        Integer dishId = params.get("dishId");
        if (dishId == null) {
            return Result.error("dishId不能为空");
        }
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        Integer flightId = user != null ? user.getCurrentFlightId() : null;
        if (flightId == null) {
            return Result.error("请先绑定航班");
        }
        FlightInfo flightInfo = flightInfoMapper.getById(flightId);
        int safeMealOrder = resolveMealOrder(params.get("mealOrder"), flightInfo == null ? null : flightInfo.getMealCount());
        insertClickLog(userId, flightId, dishId, safeMealOrder);
        return Result.success();
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
        LocalDateTime now = LocalDateTime.now();

        // Fetch previous selection for stock handling and duplicate detection
        Map<String, Object> latest = recommendationMapper.latestManualSelection(userId, flightInfo.getId(), safeMealOrder);
        Integer previousDishId = extractDishIdFromLatestSelection(latest);
        boolean existed = previousDishId != null;

        // Same dish re-selection: just update status
        if (existed && Objects.equals(previousDishId, dishId)) {
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

        // Decrease stock for new dish (before insert/update to stay atomic with rollback)
        Integer affected = dishMapper.decreaseStockAndAutoDisable(dishId, 1);
        if (affected == null || affected == 0) {
            return Result.error("该餐食库存不足，请重新选择");
        }

        boolean modified;
        if (existed) {
            // Update existing selection
            if (previousDishId != null) {
                dishMapper.increaseStockAndEnable(previousDishId, 1);
            }
            recommendationMapper.updateMealSelectionStatusAndUpdateTime(userId, flightInfo.getId(), safeMealOrder, MANUAL_SELECTION_CONFIRMED_STATUS, now);
            insertManualSelectionLog(userId, flightInfo.getId(), dishId, safeMealOrder, "MANUAL_SELECTED_UPDATE");
            modified = true;
        } else {
            try {
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
                modified = false;
            } catch (DuplicateKeyException e) {
                // Concurrent insert: fall through to update path
                if (previousDishId != null) {
                    dishMapper.increaseStockAndEnable(previousDishId, 1);
                }
                recommendationMapper.updateMealSelectionStatusAndUpdateTime(userId, flightInfo.getId(), safeMealOrder, MANUAL_SELECTION_CONFIRMED_STATUS, now);
                insertManualSelectionLog(userId, flightInfo.getId(), dishId, safeMealOrder, "MANUAL_SELECTED_UPDATE");
                modified = true;
            }
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

        Integer mealOrder = params.get("mealOrder");
        int safeMealOrder = resolveMealOrder(mealOrder, null);
        recommendationMapper.syncSubmittedLogRating(userId, flightId, rating);
        recommendationMapper.updateLatestManualRating(userId, flightId, safeMealOrder, rating);

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

    @GetMapping("/recommendation/dishes/resolve")
    public Result<Map<Integer, String>> resolveDishNames(@RequestParam String ids) {
        List<Integer> dishIds = Arrays.stream(ids.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::parseInt)
                .distinct()
                .collect(Collectors.toList());
        if (dishIds.isEmpty()) {
            return Result.success(new HashMap<>());
        }
        List<Map<String, Object>> rows = recommendationMapper.resolveDishNames(dishIds);
        Map<Integer, String> result = new HashMap<>();
        for (Map<String, Object> row : rows) {
            Integer id = parseInt(row.get("id"));
            String name = row.get("name") == null ? null : String.valueOf(row.get("name"));
            if (id != null) {
                result.put(id, name != null ? name : ("餐食#" + id));
            }
        }
        return Result.success(result);
    }

    @GetMapping("/recommendation/rating-history")
    public Result<List<Map<String, Object>>> ratingHistory() {
        Integer userId = BaseContext.getCurrentId();
        return Result.success(recommendationMapper.listRatingHistory(userId));
    }

    @GetMapping("/recommendation/history/{logId}")
    public Result<Map<String, Object>> historyDetail(@PathVariable Long logId) {
        Integer userId = BaseContext.getCurrentId();
        Map<String, Object> log = recommendationMapper.getLogById(logId);
        if (log == null) {
            return Result.error("推荐记录不存在");
        }
        Integer logUserId = parseInt(log.get("userId"));
        if (logUserId == null || !logUserId.equals(userId)) {
            return Result.error("无权查看该推荐记录");
        }
        Integer flightId = parseInt(log.get("flightId"));
        if (flightId != null) {
            FlightInfo flightInfo = flightInfoMapper.getById(flightId);
            if (flightInfo != null) {
                log.put("flightNumber", flightInfo.getFlightNumber());
                log.put("departure", flightInfo.getDeparture());
                log.put("destination", flightInfo.getDestination());
            }
        }
        List<Integer> dishIds = extractAllDishIds(String.valueOf(log.get("recommendedDishes")));
        if (!dishIds.isEmpty()) {
            List<Map<String, Object>> rows = recommendationMapper.resolveDishNames(dishIds);
            Map<Integer, String> nameMap = new HashMap<>();
            for (Map<String, Object> row : rows) {
                Integer id = parseInt(row.get("id"));
                String name = row.get("name") == null ? null : String.valueOf(row.get("name"));
                if (id != null) {
                    nameMap.put(id, name != null ? name : ("餐食#" + id));
                }
            }
            log.put("dishNames", nameMap);
        }
        Integer selectedDishId = extractDishIdFromText(log.get("userFeedback"));
        log.put("selectedDishId", selectedDishId);
        return Result.success(log);
    }

    @GetMapping("/recommendation/history/{logId}/breakdown")
    public Result<Map<String, Object>> historyBreakdown(@PathVariable Long logId) {
        Integer userId = BaseContext.getCurrentId();
        Map<String, Object> log = recommendationMapper.getLogById(logId);
        if (log == null) {
            return Result.error("推荐记录不存在");
        }
        Integer logUserId = parseInt(log.get("userId"));
        if (logUserId == null || !logUserId.equals(userId)) {
            return Result.error("无权查看该推荐记录");
        }

        Integer flightId = parseInt(log.get("flightId"));
        FlightInfo flightInfo = flightId == null ? null : flightInfoMapper.getById(flightId);

        List<Integer> dishIds = extractAllDishIds(String.valueOf(log.get("recommendedDishes")));
        if (dishIds.isEmpty()) {
            Map<String, Object> empty = new HashMap<>();
            empty.put("breakdown", new ArrayList<>());
            return Result.success(empty);
        }

        User user = userMapper.getById(userId);
        UserPreference preference = userPreferenceMapper.getByUserId(userId);
        Set<Integer> prefMealTypes = parsePreferenceMealTypes(preference == null ? null : preference.getMealTypePreferences());
        Set<String> prefFlavors = new HashSet<>(parseFlavorList(preference == null ? null : preference.getFlavorPreferences()));

        List<Integer> cabinTypes = resolveUserCabinTypes(user);
        List<RecommendationDishVO> dishVOList = recommendationMapper.listCandidateDishes(
                flightId, null, null, Math.min(dishIds.size(), 20), cabinTypes);
        Map<Integer, RecommendationDishVO> voMap = new HashMap<>();
        Map<String, Integer> dishNameIdMap = new HashMap<>();
        for (RecommendationDishVO vo : dishVOList) {
            if (vo.getDishId() != null) {
                voMap.put(vo.getDishId(), vo);
                if (vo.getDishName() != null) {
                    dishNameIdMap.put(vo.getDishName().trim(), vo.getDishId());
                }
            }
        }
        // Fill in any dish IDs that weren't returned by listCandidateDishes
        for (Integer did : dishIds) {
            if (!voMap.containsKey(did)) {
                RecommendationDishVO fallback = new RecommendationDishVO();
                fallback.setDishId(did);
                voMap.put(did, fallback);
            }
        }

        List<Map<String, Object>> recentLogs = recommendationMapper.listRecentLogs(HISTORY_WINDOW_DAYS, 5000);
        InteractionContext context = buildInteractionContext(recentLogs, voMap, dishNameIdMap);

        double[] fusionWeights = resolveFusionWeights(userId, context);
        List<Map<String, Object>> breakdown = new ArrayList<>();
        for (Integer did : dishIds) {
            RecommendationDishVO vo = voMap.get(did);
            Map<String, Object> row = new HashMap<>();
            row.put("dishId", did);
            row.put("dishName", vo != null && vo.getDishName() != null ? vo.getDishName() : ("餐食#" + did));
            if (vo != null) {
                double pmfup = calculatePmfupScore(vo, prefMealTypes, prefFlavors, flightId, context, userId,
                        flightInfo == null ? null : flightInfo.getDepartureTime(), null);
                double prmidm = calculatePrmidmScore(userId, did, context);
                double ammbc = calculateAmmbcScore(userId, did, context);
                double fused = fusionWeights[0] * pmfup + fusionWeights[1] * prmidm + fusionWeights[2] * ammbc;
                row.put("pmfup", pmfup);
                row.put("prmidm", prmidm);
                row.put("ammbc", ammbc);
                row.put("fused", Math.min(1.0, Math.max(0.0, fused)));
            } else {
                row.put("pmfup", 0.0);
                row.put("prmidm", 0.0);
                row.put("ammbc", 0.0);
                row.put("fused", 0.0);
            }
            breakdown.add(row);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("breakdown", breakdown);
        return Result.success(result);
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
                                       Set<Integer> prefMealTypes,
                                       Set<String> prefFlavors,
                                       Integer flightId,
                                       InteractionContext context,
                                       Integer userId,
                                       LocalDateTime departureTime,
                                       Integer mealOrder) {
        if (item == null || item.getDishId() == null) {
            return 0.0;
        }

        double prefScore = 0.2;
        if (!prefMealTypes.isEmpty() && item.getMealType() != null && prefMealTypes.contains(item.getMealType())) {
            prefScore += prefMealTypes.size() == 1 ? 0.45 : 0.38;
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

        return clamp01(prefScore);
    }

    private double calculatePrmidmScore(Integer userId, Integer dishId, InteractionContext context) {
        if (dishId == null || userId == null) {
            return 0.0;
        }
        Set<String> targetFlavors = context.dishFlavorTags.getOrDefault(dishId, Collections.emptySet());
        Map<String, Double> recentFlavor = context.userRecentFlavorScore.getOrDefault(userId, Collections.emptyMap());
        Map<String, Double> longFlavor = context.userLongFlavorScore.getOrDefault(userId, Collections.emptyMap());

        double recentFlavorScore = 0.0;
        double historyFlavorScore = 0.0;
        for (String flavor : targetFlavors) {
            recentFlavorScore += recentFlavor.getOrDefault(flavor, 0.0);
            historyFlavorScore += longFlavor.getOrDefault(flavor, 0.0);
        }

        double interest = context.userDishScore
                .getOrDefault(userId, Collections.emptyMap())
                .getOrDefault(dishId, 0.0);

        double recentPreference = normalizeSignal(recentFlavorScore);
        double historyPreference = normalizeSignal(historyFlavorScore);
        double driftBoost = clamp01(recentPreference - historyPreference);

        double shortTermDishSignal = clamp01(interest / 8.0);
        return clamp01(0.60 * recentPreference + 0.30 * driftBoost + 0.10 * shortTermDishSignal);
    }

    private double calculateAmmbcScore(Integer userId, Integer dishId, InteractionContext context) {
        if (dishId == null || userId == null) {
            return 0.0;
        }

        Map<Integer, Double> current = context.userDishScore.getOrDefault(userId, Collections.emptyMap());
        if (current.isEmpty()) {
            return 0.0;
        }
        double simWeighted = 0.0;
        double simTotal = 0.0;
        int neighborCount = 0;
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
            int overlap = overlapCount(current, otherVector);
            if (overlap <= 0) {
                continue;
            }
            double adjustedSim = sim * (overlap / (overlap + CF_SHRINK_LAMBDA));
            if (adjustedSim <= 0) {
                continue;
            }
            simWeighted += adjustedSim * otherVector.get(dishId);
            simTotal += adjustedSim;
            neighborCount++;
        }
        if (simTotal <= 0) {
            return 0.0;
        }
        double collaborative = clamp01((simWeighted / simTotal) / 8.0);
        int exposureCount = context.dishExposureCount.getOrDefault(dishId, 0);
        double popularityDebias = 1.0 / (1.0 + Math.log1p(Math.max(0, exposureCount)) / 6.0);
        double confidence = clamp01(simTotal / Math.max(1.0, neighborCount * 0.45));
        return clamp01(collaborative * popularityDebias * (0.70 + 0.30 * confidence));
    }

    private InteractionContext buildInteractionContext(List<Map<String, Object>> logs,
                                                       Map<Integer, RecommendationDishVO> candidateMap,
                                                       Map<String, Integer> dishNameIdMap) {
        InteractionContext ctx = new InteractionContext();
        Set<Integer> allDishIds = collectDishIdsFromLogs(logs);
        allDishIds.addAll(candidateMap.keySet());
        ctx.dishFlavorTags.putAll(loadDishFlavorTags(allDishIds));
        for (RecommendationDishVO dish : candidateMap.values()) {
            if (dish == null || dish.getDishId() == null) {
                continue;
            }
            Set<String> flavors = parseFlavorTokens(dish.getFlavorTags());
            if (!flavors.isEmpty()) {
                ctx.dishFlavorTags.put(dish.getDishId(), flavors);
            }
        }
        for (Map<String, Object> row : logs) {
            Integer uid = parseInt(row.get("userId"));
            if (uid == null) {
                continue;
            }

            String feedback = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
            LocalDateTime createTime = parseDateTime(row.get("createTime"));
            double decay = timeDecay(createTime);
            boolean behaviorSignal = false;

            Set<Integer> relatedDishIds = extractDishIds(row.get("recommendedDishes"), dishNameIdMap);
            for (Integer did : relatedDishIds) {
                addScore(ctx.userDishScore, uid, did, EXPOSURE_SCORE_WEIGHT * decay);
                increaseDishExposure(ctx, did);
            }

            Integer selectedDishId = extractDishIdFromText(feedback);
            if (selectedDishId != null) {
                if (feedback.startsWith("MANUAL_SELECTED")) {
                    addScore(ctx.userDishScore, uid, selectedDishId, 5.0 * decay);
                    addFlavorDriftSignal(ctx, uid, selectedDishId, createTime, decay, 2.4);
                    behaviorSignal = true;
                } else if (feedback.startsWith("AUTO_SELECTED_OVERDUE")) {
                    addScore(ctx.userDishScore, uid, selectedDishId, 3.0 * decay);
                    addFlavorDriftSignal(ctx, uid, selectedDishId, createTime, decay, 1.8);
                    behaviorSignal = true;
                } else if (feedback.startsWith("CLICK")) {
                    addScore(ctx.userDishScore, uid, selectedDishId, 2.0 * decay);
                    addFlavorDriftSignal(ctx, uid, selectedDishId, createTime, decay, 1.4);
                    behaviorSignal = true;
                }
                increaseDishExposure(ctx, selectedDishId);
            }

            Integer rating = parseInt(row.get("userRating"));
            if (rating != null && rating > 0 && selectedDishId != null) {
                addScore(ctx.userDishScore, uid, selectedDishId, (rating >= 4 ? 2.0 : 1.0) * decay); // click/interest signal
                addFlavorDriftSignal(ctx, uid, selectedDishId, createTime, decay, rating >= 4 ? 1.4 : 0.8);
                behaviorSignal = true;
            }

            if (behaviorSignal) {
                markBehaviorSignal(ctx, uid);
            }
        }
        return ctx;
    }

    private void markBehaviorSignal(InteractionContext context, Integer userId) {
        if (context == null || userId == null) {
            return;
        }
        int signal = context.userBehaviorSignal.getOrDefault(userId, 0);
        context.userBehaviorSignal.put(userId, signal + 1);
    }

    private int resolveBehaviorSignalCount(Integer userId, InteractionContext context) {
        if (userId == null || context == null) {
            return 0;
        }
        return context.userBehaviorSignal.getOrDefault(userId, 0);
    }

    private double[] resolveFusionWeights(Integer userId, InteractionContext context) {
        if (userId == null || context == null) {
            return new double[]{0.60, 0.25, 0.15};
        }
        int signalCount = resolveBehaviorSignalCount(userId, context);
        double signalConfidence = clamp01(Math.log1p(signalCount) / Math.log(15.0));

        int behaviorCoverageSize = context.userDishScore
                .getOrDefault(userId, Collections.emptyMap())
                .size();
        double behaviorCoverage = clamp01(behaviorCoverageSize / 10.0);

        double recentSignal = sumSignal(context.userRecentFlavorScore.getOrDefault(userId, Collections.emptyMap()));
        double historySignal = sumSignal(context.userLongFlavorScore.getOrDefault(userId, Collections.emptyMap()));
        double driftEvidence = clamp01((recentSignal + historySignal) / 12.0);

        double pmfupRaw = 0.46 + 0.22 * (1.0 - signalConfidence) + 0.08 * (1.0 - driftEvidence);
        double prmidmRaw = 0.22 + 0.30 * driftEvidence + 0.12 * signalConfidence;
        double ammbcRaw = 0.16 + 0.26 * signalConfidence + 0.18 * behaviorCoverage;

        double total = pmfupRaw + prmidmRaw + ammbcRaw;
        if (total <= 0) {
            return new double[]{0.60, 0.25, 0.15};
        }
        return new double[]{pmfupRaw / total, prmidmRaw / total, ammbcRaw / total};
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

    private void increaseDishExposure(InteractionContext context, Integer dishId) {
        if (context == null || dishId == null) {
            return;
        }
        int count = context.dishExposureCount.getOrDefault(dishId, 0);
        context.dishExposureCount.put(dishId, count + 1);
    }

    private Set<Integer> collectDishIdsFromLogs(List<Map<String, Object>> logs) {
        Set<Integer> result = new HashSet<>();
        if (logs == null || logs.isEmpty()) {
            return result;
        }
        for (Map<String, Object> row : logs) {
            if (row == null) {
                continue;
            }
            result.addAll(extractAllDishIds(String.valueOf(row.get("recommendedDishes"))));
            result.addAll(extractAllDishIds(String.valueOf(row.get("userFeedback"))));
        }
        return result;
    }

    private Map<Integer, Set<String>> loadDishFlavorTags(Set<Integer> dishIds) {
        Map<Integer, Set<String>> result = new HashMap<>();
        if (dishIds == null || dishIds.isEmpty() || recommendationMapper == null) {
            return result;
        }
        List<Integer> validDishIds = dishIds.stream()
                .filter(Objects::nonNull)
                .filter(id -> id > 0)
                .distinct()
                .limit(1200)
                .toList();
        if (validDishIds.isEmpty()) {
            return result;
        }
        try {
            List<Map<String, Object>> rows = recommendationMapper.listDishFlavorTagsByIds(validDishIds);
            if (rows == null || rows.isEmpty()) {
                return result;
            }
            for (Map<String, Object> row : rows) {
                Integer dishId = parseInt(row.get("dishId"));
                if (dishId == null) {
                    continue;
                }
                Set<String> flavors = parseFlavorTokens(row.get("flavorTags") == null ? null : String.valueOf(row.get("flavorTags")));
                if (!flavors.isEmpty()) {
                    result.put(dishId, flavors);
                }
            }
        } catch (Exception ex) {
            log.warn("加载菜品口味标签失败，已使用候选集兜底。dishCount={}", validDishIds.size(), ex);
        }
        return result;
    }

    private void addFlavorDriftSignal(InteractionContext context,
                                      Integer userId,
                                      Integer dishId,
                                      LocalDateTime createTime,
                                      double decay,
                                      double weight) {
        if (context == null || userId == null || dishId == null || weight <= 0) {
            return;
        }
        Set<String> flavors = context.dishFlavorTags.getOrDefault(dishId, Collections.emptySet());
        if (flavors.isEmpty()) {
            return;
        }
        if (createTime == null) {
            addFlavorScore(context.userLongFlavorScore, userId, flavors, weight * decay);
            return;
        }
        if (isRecentWindow(createTime, RECENT_WINDOW_DAYS)) {
            addFlavorScore(context.userRecentFlavorScore, userId, flavors, weight * decay);
            return;
        }
        if (isRecentWindow(createTime, HISTORY_WINDOW_DAYS)) {
            addFlavorScore(context.userLongFlavorScore, userId, flavors, weight * decay);
        }
    }

    private void addFlavorScore(Map<Integer, Map<String, Double>> source,
                                Integer userId,
                                Set<String> flavors,
                                double score) {
        if (source == null || userId == null || flavors == null || flavors.isEmpty()) {
            return;
        }
        Map<String, Double> profile = source.computeIfAbsent(userId, k -> new HashMap<>());
        for (String flavor : flavors) {
            if (flavor == null || flavor.trim().isEmpty()) {
                continue;
            }
            profile.put(flavor, profile.getOrDefault(flavor, 0.0) + score);
        }
    }

    private boolean isRecentWindow(LocalDateTime createTime, int days) {
        if (createTime == null) {
            return false;
        }
        return !createTime.isBefore(LocalDateTime.now().minusDays(days));
    }

    private double normalizeSignal(double score) {
        if (score <= 0) {
            return 0.0;
        }
        return clamp01(score / (score + 2.0));
    }

    private double sumSignal(Map<String, Double> source) {
        if (source == null || source.isEmpty()) {
            return 0.0;
        }
        double total = 0.0;
        for (Double value : source.values()) {
            if (value == null || value <= 0) {
                continue;
            }
            total += value;
        }
        return total;
    }

    private Set<String> parseFlavorTokens(String raw) {
        Set<String> result = new HashSet<>();
        if (raw == null || raw.trim().isEmpty()) {
            return result;
        }
        String compact = raw.replace("[", "")
                .replace("]", "")
                .replace("\"", "")
                .replace("、", ",")
                .replace("/", ",")
                .replace("|", ",")
                .replace(";", ",")
                .replace("，", ",");
        for (String token : compact.split(",")) {
            String flavor = token == null ? "" : token.trim();
            if (!flavor.isEmpty()) {
                result.add(flavor);
            }
        }
        return result;
    }

    private Set<Integer> extractDishIds(Object value,
                                        Map<String, Integer> dishNameIdMap) {
        Set<Integer> result = new HashSet<>();
        if (value == null) {
            return result;
        }
        String text = String.valueOf(value);
        for (Integer id : extractAllDishIds(text)) {
            result.add(id);
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

    private int overlapCount(Map<Integer, Double> a, Map<Integer, Double> b) {
        if (a.isEmpty() || b.isEmpty()) {
            return 0;
        }
        int overlap = 0;
        for (Integer key : a.keySet()) {
            if (b.containsKey(key)) {
                overlap++;
            }
        }
        return overlap;
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
        private final Map<Integer, Integer> dishExposureCount = new HashMap<>();
        private final Map<Integer, Integer> userBehaviorSignal = new HashMap<>();
        private final Map<Integer, Map<String, Double>> userRecentFlavorScore = new HashMap<>();
        private final Map<Integer, Map<String, Double>> userLongFlavorScore = new HashMap<>();
        private final Map<Integer, Set<String>> dishFlavorTags = new HashMap<>();
    }

    private String validatePreference(UserPreference preference) {
        if (preference == null) {
            return "偏好参数不能为空";
        }
        Set<Integer> mealTypes = parsePreferenceMealTypes(preference.getMealTypePreferences());
        for (Integer mt : mealTypes) {
            if (!ALLOWED_MEAL_TYPES.contains(mt)) {
                return "mealTypePreferences包含非法餐型";
            }
        }
        List<String> flavors = parseFlavorList(preference.getFlavorPreferences());
        for (String item : flavors) {
            if (!ALLOWED_FLAVORS.contains(item)) {
                return "flavorPreferences包含非法口味:" + item;
            }
        }
        return null;
    }

    private Set<Integer> parsePreferenceMealTypes(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return Collections.emptySet();
        }
        String compact = raw.replace("[", "").replace("]", "").replace("\"", "").trim();
        if (compact.isEmpty()) {
            return Collections.emptySet();
        }
        Set<Integer> result = new LinkedHashSet<>();
        for (String token : compact.split(",")) {
            try {
                int v = Integer.parseInt(token.trim());
                if (ALLOWED_MEAL_TYPES.contains(v)) {
                    result.add(v);
                }
            } catch (Exception ex) {
                // skip invalid tokens
            }
        }
        return result;
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

    private void insertClickLog(Integer userId, Integer flightId, Integer dishId, Integer mealOrder) {
        Map<String, Object> recommendLog = new HashMap<>();
        recommendLog.put("userId", userId);
        recommendLog.put("flightId", flightId);
        recommendLog.put("recommendedDishes", "[" + dishId + "]");
        recommendLog.put("algorithmType", resolveAlgorithmType(userId));
        recommendLog.put("userFeedback", "CLICK:dishId=" + dishId + ":mealOrder=" + mealOrder);
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
