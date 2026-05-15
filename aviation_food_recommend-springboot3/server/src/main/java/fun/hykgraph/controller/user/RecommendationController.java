package fun.hykgraph.controller.user;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.entity.FlightAnnouncement;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.entity.User;

import fun.hykgraph.mapper.DishMapper;
import fun.hykgraph.mapper.FlightAnnouncementMapper;
import fun.hykgraph.mapper.FlightInfoMapper;
import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.mapper.UserMapper;

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
    public Result<Map<String, Object>> getPreference() {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        if (user == null) {
            return Result.success(null);
        }
        Map<String, Object> pref = new HashMap<>();
        pref.put("userId", user.getId());
        pref.put("mealTypePreferences", user.getMealTypePreferences());
        pref.put("flavorPreferences", user.getFlavorPreferences());

        pref.put("dietaryNotes", user.getDietaryNotes());
        pref.put("updateTime", user.getUpdateTime());
        pref.put("createTime", user.getCreateTime());
        return Result.success(pref);
    }

    @PutMapping("/preference")
    public Result savePreference(@RequestBody Map<String, Object> params) {
        Integer userId = BaseContext.getCurrentId();
        String mealTypePreferences = params.get("mealTypePreferences") != null ? String.valueOf(params.get("mealTypePreferences")) : null;
        String flavorPreferences = params.get("flavorPreferences") != null ? String.valueOf(params.get("flavorPreferences")) : null;

        String dietaryNotes = params.get("dietaryNotes") != null ? String.valueOf(params.get("dietaryNotes")) : null;
        String validation = validatePreference(mealTypePreferences, flavorPreferences);
        if (validation != null) {
            return Result.error(validation);
        }
        LocalDateTime now = LocalDateTime.now();
        int completed = parseFlavorList(flavorPreferences).isEmpty() ? 0 : 1;
        User user = User.builder()
                .id(userId)
                .mealTypePreferences(mealTypePreferences)
                .flavorPreferences(flavorPreferences)

                .dietaryNotes(dietaryNotes)
                .preferenceCompleted(completed)
                .updateTime(now)
                .build();
        userMapper.update(user);
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
        User prefUser = userMapper.getById(userId);
        Set<Integer> prefMealTypes = parsePreferenceMealTypes(prefUser == null ? null : prefUser.getMealTypePreferences());
        Set<String> prefFlavors = new HashSet<>(parseFlavorList(prefUser == null ? null : prefUser.getFlavorPreferences()));

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
        Set<Integer> prefMealTypes = parsePreferenceMealTypes(user == null ? null : user.getMealTypePreferences());
        Set<String> prefFlavors = new HashSet<>(parseFlavorList(user == null ? null : user.getFlavorPreferences()));

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

    /**
     * 离线评测接口：对不同权重配置计算 Top-1 / Top-3 / MRR。
     * 按时间划分训练/测试集，仅用测试集的时间点之前的日志构建上下文，避免数据泄露。
     */
    @GetMapping("/recommendation/evaluate")
    public Result<Map<String, Object>> evaluate() {
        List<Map<String, Object>> allLogs = recommendationMapper.listRecentLogs(HISTORY_WINDOW_DAYS, 5000);
        if (allLogs == null || allLogs.size() < 30) {
            return Result.error("日志数量不足，无法评测");
        }

        // 按 create_time 升序
        allLogs.sort((a, b) -> {
            Object ta = a.get("createTime");
            Object tb = b.get("createTime");
            if (ta == null && tb == null) return 0;
            if (ta == null) return -1;
            if (tb == null) return 1;
            return String.valueOf(ta).compareTo(String.valueOf(tb));
        });

        // 提取 MANUAL_SELECTED 日志作为 ground truth
        List<Map<String, Object>> manualLogs = new ArrayList<>();
        for (Map<String, Object> row : allLogs) {
            String fb = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
            if (fb.startsWith("MANUAL_SELECTED")) {
                manualLogs.add(row);
            }
        }

        // 按时间取后 20% 作为测试集（至少 5 条）
        int splitIdx = Math.max(1, (int) (manualLogs.size() * 0.8));
        List<Map<String, Object>> testLogs = manualLogs.subList(splitIdx, manualLogs.size());
        if (testLogs.size() < 5) {
            testLogs = manualLogs.subList(Math.max(0, manualLogs.size() - 5), manualLogs.size());
        }

        // 权重配置
        double[][] weightConfigs = {
            {1.0, 0.0, 0.0},          // 纯 PMFUP
            {0.0, 0.0, 1.0},          // 纯 AMMBC (User-CF)
            {0.60, 0.25, 0.15},       // 固定权重
        };
        String[] configNames = {"纯PMFUP", "纯User-CF", "固定权重[0.60,0.25,0.15]", "自适应融合"};

        Map<String, Object> result = new HashMap<>();
        result.put("testSize", testLogs.size());
        result.put("totalManualLogs", manualLogs.size());
        List<Map<String, Object>> results = new ArrayList<>();

        for (int ci = 0; ci < weightConfigs.length; ci++) {
            double[] fixedW = weightConfigs[ci];
            int top1 = 0, top3 = 0;
            double mrrSum = 0.0;
            int valid = 0;

            for (Map<String, Object> testLog : testLogs) {
                Integer uid = parseInt(testLog.get("userId"));
                Integer fid = parseInt(testLog.get("flightId"));
                Integer truthDishId = extractDishIdFromText(testLog.get("userFeedback"));
                if (uid == null || fid == null || truthDishId == null) continue;

                // 获取该时间点之前的日志（避免数据泄露）
                Object testTime = testLog.get("createTime");
                List<Map<String, Object>> logsBefore = new ArrayList<>();
                for (Map<String, Object> row : allLogs) {
                    Object t = row.get("createTime");
                    if (t != null && testTime != null
                            && String.valueOf(t).compareTo(String.valueOf(testTime)) < 0) {
                        logsBefore.add(row);
                    }
                }

                List<Integer> ranked = evaluateRanking(uid, fid, truthDishId, logsBefore, fixedW);
                if (ranked == null || ranked.isEmpty()) continue;

                valid++;
                if (!ranked.isEmpty() && Objects.equals(ranked.get(0), truthDishId)) top1++;
                for (int k = 0; k < Math.min(3, ranked.size()); k++) {
                    if (Objects.equals(ranked.get(k), truthDishId)) { top3++; break; }
                }
                for (int r = 0; r < ranked.size(); r++) {
                    if (Objects.equals(ranked.get(r), truthDishId)) {
                        mrrSum += 1.0 / (r + 1);
                        break;
                    }
                }
            }

            Map<String, Object> row = new HashMap<>();
            row.put("config", configNames[ci]);
            row.put("valid", valid);
            row.put("top1", valid > 0 ? String.format("%.1f%%", 100.0 * top1 / valid) : "N/A");
            row.put("top3", valid > 0 ? String.format("%.1f%%", 100.0 * top3 / valid) : "N/A");
            row.put("mrr", valid > 0 ? String.format("%.4f", mrrSum / valid) : "N/A");
            results.add(row);
        }

        // 自适应权重
        {
            int top1 = 0, top3 = 0, valid = 0;
            double mrrSum = 0.0;
            for (Map<String, Object> testLog : testLogs) {
                Integer uid = parseInt(testLog.get("userId"));
                Integer fid = parseInt(testLog.get("flightId"));
                Integer truthDishId = extractDishIdFromText(testLog.get("userFeedback"));
                if (uid == null || fid == null || truthDishId == null) continue;

                Object testTime = testLog.get("createTime");
                List<Map<String, Object>> logsBefore = new ArrayList<>();
                for (Map<String, Object> row2 : allLogs) {
                    Object t = row2.get("createTime");
                    if (t != null && testTime != null
                            && String.valueOf(t).compareTo(String.valueOf(testTime)) < 0) {
                        logsBefore.add(row2);
                    }
                }

                List<Integer> ranked = evaluateRanking(uid, fid, truthDishId, logsBefore, null);
                if (ranked == null || ranked.isEmpty()) continue;

                valid++;
                if (!ranked.isEmpty() && Objects.equals(ranked.get(0), truthDishId)) top1++;
                for (int k = 0; k < Math.min(3, ranked.size()); k++) {
                    if (Objects.equals(ranked.get(k), truthDishId)) { top3++; break; }
                }
                for (int r = 0; r < ranked.size(); r++) {
                    if (Objects.equals(ranked.get(r), truthDishId)) {
                        mrrSum += 1.0 / (r + 1);
                        break;
                    }
                }
            }
            Map<String, Object> row = new HashMap<>();
            row.put("config", configNames[3]);
            row.put("valid", valid);
            row.put("top1", valid > 0 ? String.format("%.1f%%", 100.0 * top1 / valid) : "N/A");
            row.put("top3", valid > 0 ? String.format("%.1f%%", 100.0 * top3 / valid) : "N/A");
            row.put("mrr", valid > 0 ? String.format("%.4f", mrrSum / valid) : "N/A");
            results.add(row);
        }

        result.put("results", results);
        return Result.success(result);
    }

    /**
     * 核心评分逻辑（从 list() 提取），返回按 fusedScore 降序排列的 dishId 列表。
     * 若 fixedWeights 非空则使用固定权重，否则调用自适应权重解析器。
     */
    private List<Integer> evaluateRanking(Integer userId, Integer flightId,
                                           Integer truthDishId,
                                           List<Map<String, Object>> logsBefore,
                                           double[] fixedWeights) {
        // 随机基线
        if (fixedWeights != null && fixedWeights.length > 0 && fixedWeights[0] == -1) {
            return evaluateRankingRandom(flightId, userId);
        }
        // 流行度基线
        if (fixedWeights != null && fixedWeights.length > 0 && fixedWeights[0] == -2) {
            return evaluateRankingPopular(logsBefore, flightId, userId);
        }

        try {
            FlightInfo flightInfo = flightInfoMapper.getById(flightId);
            if (flightInfo == null) { log.info("eval: flightInfo null flightId={}", flightId); return null; }

            List<Integer> cabinTypes = resolveCabinTypes(flightInfo, userId);
            List<RecommendationDishVO> candidates = recommendationMapper.listCandidateDishes(
                    flightId, null, null, 30, cabinTypes);
            if (candidates.isEmpty()) { log.info("eval: no candidates userId={} flightId={}", userId, flightId); return null; }

            Map<Integer, RecommendationDishVO> candidateMap = candidates.stream()
                    .filter(it -> it.getDishId() != null)
                    .collect(Collectors.toMap(RecommendationDishVO::getDishId, it -> it, (a, b) -> a));
            Map<String, Integer> dishNameIdMap = candidates.stream()
                    .filter(it -> it.getDishId() != null && it.getDishName() != null)
                    .collect(Collectors.toMap(it -> it.getDishName().trim(),
                            RecommendationDishVO::getDishId, (a, b) -> a));

            InteractionContext ctx = buildInteractionContext(logsBefore, candidateMap, dishNameIdMap);
            User prefUser = userMapper.getById(userId);
            Set<Integer> prefMealTypes = parsePreferenceMealTypes(
                    prefUser == null ? null : prefUser.getMealTypePreferences());
            Set<String> prefFlavors = new HashSet<>(
                    parseFlavorList(prefUser == null ? null : prefUser.getFlavorPreferences()));

            double[] weights;
            if (fixedWeights != null) {
                weights = fixedWeights;
            } else {
                weights = resolveFusionWeights(userId, ctx);
            }

            // 对每个候选打分
            List<RecommendationDishVO> scored = new ArrayList<>();
            for (RecommendationDishVO item : candidates) {
                if (item.getDishId() == null) continue;
                double s1 = calculatePmfupScore(item, prefMealTypes, prefFlavors,
                        flightId, ctx, userId, flightInfo.getDepartureTime(), 1);
                double s2 = calculatePrmidmScore(userId, item.getDishId(), ctx);
                double s3 = calculateAmmbcScore(userId, item.getDishId(), ctx);
                double fused = weights[0] * s1 + weights[1] * s2 + weights[2] * s3;
                item.setScore(Math.min(1.0, Math.max(0.0, fused)));
                scored.add(item);
            }

            scored.sort((a, b) -> Double.compare(b.getScore(), a.getScore()));
            return scored.stream().map(RecommendationDishVO::getDishId).collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("评测单条失败 userId={} flightId={}", userId, flightId, e);
            return null;
        }
    }

    /** 随机基线：获取候选菜品并随机打乱 */
    private List<Integer> evaluateRankingRandom(Integer flightId, Integer userId) {
        FlightInfo fi = flightInfoMapper.getById(flightId);
        if (fi == null) return null;
        List<Integer> cts = resolveCabinTypes(fi, userId);
        List<RecommendationDishVO> candidates = recommendationMapper.listCandidateDishes(flightId, null, null, 30, cts);
        if (candidates.isEmpty()) return null;
        List<Integer> ids = candidates.stream().map(RecommendationDishVO::getDishId).filter(Objects::nonNull).collect(Collectors.toList());
        Collections.shuffle(ids);
        return ids;
    }

    /** 流行度基线：按曝光次数降序排列 */
    private List<Integer> evaluateRankingPopular(List<Map<String, Object>> logsBefore, Integer flightId, Integer userId) {
        FlightInfo fi = flightInfoMapper.getById(flightId);
        if (fi == null) return null;
        List<Integer> cts = resolveCabinTypes(fi, userId);
        List<RecommendationDishVO> candidates = recommendationMapper.listCandidateDishes(flightId, null, null, 30, cts);
        if (candidates.isEmpty()) return null;
        // 统计曝光次数
        Map<Integer, Integer> exposure = new HashMap<>();
        for (Map<String, Object> row : logsBefore) {
            String rd = row.get("recommendedDishes") == null ? "" : String.valueOf(row.get("recommendedDishes"));
            for (Integer did : extractAllDishIds(rd)) {
                exposure.merge(did, 1, Integer::sum);
            }
        }
        List<RecommendationDishVO> sorted = new ArrayList<>(candidates);
        sorted.sort((a, b) -> Integer.compare(
            exposure.getOrDefault(b.getDishId(), 0),
            exposure.getOrDefault(a.getDishId(), 0)));
        return sorted.stream().map(RecommendationDishVO::getDishId).filter(Objects::nonNull).collect(Collectors.toList());
    }

    private List<Integer> resolveCabinTypes(FlightInfo flightInfo, Integer userId) {
        User user = userMapper.getById(userId);
        int cabinType = user != null && user.getCabinType() != null ? user.getCabinType() : CABIN_ECONOMY;
        if (cabinType == CABIN_FIRST) {
            return Arrays.asList(CABIN_FIRST, CABIN_BUSINESS, CABIN_ECONOMY);
        }
        if (cabinType == CABIN_BUSINESS) {
            return Arrays.asList(CABIN_BUSINESS, CABIN_ECONOMY);
        }
        return Collections.singletonList(CABIN_ECONOMY);
    }

    /**
     * 亚采样评测：在 45 / 60 / 90 三档用户规模下对比自适应融合与固定权重。
     * 验证"自适应机制随数据规模增长而改善"的趋势假设。
     */
    @GetMapping("/recommendation/evaluate/subsample")
    public Result<Map<String, Object>> evaluateSubsample() {
        List<Map<String, Object>> allLogs = recommendationMapper.listRecentLogs(HISTORY_WINDOW_DAYS, 5000);
        if (allLogs == null || allLogs.size() < 30) {
            return Result.error("日志数量不足");
        }

        // 收集所有 userId
        Set<Integer> allUserIds = new HashSet<>();
        for (Map<String, Object> row : allLogs) {
            Integer uid = parseInt(row.get("userId"));
            if (uid != null) allUserIds.add(uid);
        }
        List<Integer> userIdList = new ArrayList<>(allUserIds);
        Collections.shuffle(userIdList, new Random(42)); // 固定种子可复现

        int[] sizes = {45, 60, Math.min(90, userIdList.size())};
        Map<String, Object> result = new HashMap<>();
        result.put("totalUsers", userIdList.size());
        List<Map<String, Object>> scaleResults = new ArrayList<>();

        for (int size : sizes) {
            if (size > userIdList.size()) continue;
            Set<Integer> subset = new HashSet<>(userIdList.subList(0, size));

            // 仅使用子集用户的日志
            List<Map<String, Object>> subsetLogs = new ArrayList<>();
            for (Map<String, Object> row : allLogs) {
                Integer uid = parseInt(row.get("userId"));
                if (uid != null && subset.contains(uid)) subsetLogs.add(row);
            }
            subsetLogs.sort((a, b) -> {
                Object ta = a.get("createTime"), tb = b.get("createTime");
                if (ta == null && tb == null) return 0;
                if (ta == null) return -1;
                if (tb == null) return 1;
                return String.valueOf(ta).compareTo(String.valueOf(tb));
            });

            // 提取 MANUAL_SELECTED 作为 ground truth
            List<Map<String, Object>> manualLogs = new ArrayList<>();
            for (Map<String, Object> row : subsetLogs) {
                String fb = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
                if (fb.startsWith("MANUAL_SELECTED")) manualLogs.add(row);
            }
            int splitIdx = Math.max(1, (int) (manualLogs.size() * 0.8));
            List<Map<String, Object>> testLogs = manualLogs.subList(splitIdx, manualLogs.size());
            if (testLogs.size() < 3) testLogs = manualLogs.subList(Math.max(0, manualLogs.size() - 3), manualLogs.size());

            double[] fixedW = {0.60, 0.25, 0.15};
            int[] fixedMetrics = runEvalOnLogs(subsetLogs, testLogs, fixedW);
            int[] adaptiveMetrics = runEvalOnLogs(subsetLogs, testLogs, null);
            int[] randomMetrics = runEvalRandom(subsetLogs, testLogs);
            int[] popularMetrics = runEvalPopular(subsetLogs, testLogs);
            int tsz = testLogs.size();

            Map<String, Object> row = new HashMap<>();
            row.put("userCount", size);
            row.put("testSize", tsz);
            row.put("manualLogs", manualLogs.size());
            // 四个算法 × 四个K值
            for (String key : new String[]{"fixed","adaptive","random","popular"}) {
                int[] m = key.equals("fixed")?fixedMetrics:key.equals("adaptive")?adaptiveMetrics:key.equals("random")?randomMetrics:popularMetrics;
                row.put(key+"Top1", tsz>0?String.format("%.1f%%",100.0*m[0]/tsz):"N/A");
                row.put(key+"Top3", tsz>0?String.format("%.1f%%",100.0*m[1]/tsz):"N/A");
                row.put(key+"Top5", tsz>0?String.format("%.1f%%",100.0*m[2]/tsz):"N/A");
                row.put(key+"Top10", tsz>0?String.format("%.1f%%",100.0*m[3]/tsz):"N/A");
                row.put(key+"MRR", tsz>0?String.format("%.4f",m[4]/(double)tsz/10000.0):"N/A");
            }
            row.put("top3Gap", tsz>0?String.format("%+.1f%%",100.0*(adaptiveMetrics[1]-fixedMetrics[1])/tsz):"N/A");
            scaleResults.add(row);
        }

        result.put("scales", scaleResults);
        return Result.success(result);
    }

    /** 对指定测试集运行评测，返回 [top1, top3, top5, top10, mrrSum×10000] */
    private int[] runEvalOnLogs(List<Map<String, Object>> allLogs,
                                List<Map<String, Object>> testLogs,
                                double[] fixedWeights) {
        int top1 = 0, top3 = 0, top5 = 0, top10 = 0;
        double mrrSum = 0.0;
        for (Map<String, Object> testLog : testLogs) {
            Integer uid = parseInt(testLog.get("userId"));
            Integer fid = parseInt(testLog.get("flightId"));
            Integer truthDishId = extractDishIdFromText(testLog.get("userFeedback"));
            if (uid == null || fid == null || truthDishId == null) continue;
            Object testTime = testLog.get("createTime");
            List<Map<String, Object>> logsBefore = new ArrayList<>();
            for (Map<String, Object> row2 : allLogs) {
                Object t = row2.get("createTime");
                if (t != null && testTime != null
                        && String.valueOf(t).compareTo(String.valueOf(testTime)) < 0) {
                    logsBefore.add(row2);
                }
            }
            List<Integer> ranked = evaluateRanking(uid, fid, truthDishId, logsBefore, fixedWeights);
            if (ranked == null || ranked.isEmpty()) continue;
            if (Objects.equals(ranked.get(0), truthDishId)) top1++;
            for (int k = 0; k < Math.min(3, ranked.size()); k++)
                if (Objects.equals(ranked.get(k), truthDishId)) { top3++; break; }
            for (int k = 0; k < Math.min(5, ranked.size()); k++)
                if (Objects.equals(ranked.get(k), truthDishId)) { top5++; break; }
            for (int k = 0; k < Math.min(10, ranked.size()); k++)
                if (Objects.equals(ranked.get(k), truthDishId)) { top10++; break; }
            for (int r = 0; r < ranked.size(); r++)
                if (Objects.equals(ranked.get(r), truthDishId)) { mrrSum += 1.0/(r+1); break; }
        }
        return new int[]{top1, top3, top5, top10, (int)Math.round(mrrSum*10000)};
    }

    /** 随机基线：shuffle 候选列表 */
    private int[] runEvalRandom(List<Map<String, Object>> allLogs,
                                List<Map<String, Object>> testLogs) {
        int top1=0,top3=0,top5=0,top10=0;
        double mrr=0;
        for (Map<String, Object> tl : testLogs) {
            Integer uid=parseInt(tl.get("userId")), fid=parseInt(tl.get("flightId"));
            Integer tid=extractDishIdFromText(tl.get("userFeedback"));
            if (uid==null||fid==null||tid==null) continue;
            Object tt=tl.get("createTime");
            List<Map<String, Object>> before = new ArrayList<>();
            for (Map<String, Object> r : allLogs) {
                Object t=r.get("createTime");
                if (t!=null&&tt!=null&&String.valueOf(t).compareTo(String.valueOf(tt))<0) before.add(r);
            }
            List<Integer> ranked = evaluateRanking(uid,fid,tid,before,new double[]{-1,0,0}); // -1 triggers random
            if (ranked==null||ranked.isEmpty()) continue;
            if (Objects.equals(ranked.get(0),tid)) top1++;
            for (int k=0;k<Math.min(3,ranked.size());k++) if(Objects.equals(ranked.get(k),tid)){top3++;break;}
            for (int k=0;k<Math.min(5,ranked.size());k++) if(Objects.equals(ranked.get(k),tid)){top5++;break;}
            for (int k=0;k<Math.min(10,ranked.size());k++) if(Objects.equals(ranked.get(k),tid)){top10++;break;}
            for (int r=0;r<ranked.size();r++) if(Objects.equals(ranked.get(r),tid)){mrr+=1.0/(r+1);break;}
        }
        return new int[]{top1,top3,top5,top10,(int)Math.round(mrr*10000)};
    }

    /** 流行度基线：按菜品曝光次数降序排列 */
    private int[] runEvalPopular(List<Map<String, Object>> allLogs,
                                  List<Map<String, Object>> testLogs) {
        int top1=0,top3=0,top5=0,top10=0; double mrr=0;
        for (Map<String, Object> tl : testLogs) {
            Integer uid=parseInt(tl.get("userId")), fid=parseInt(tl.get("flightId"));
            Integer tid=extractDishIdFromText(tl.get("userFeedback"));
            if (uid==null||fid==null||tid==null) continue;
            Object tt=tl.get("createTime");
            List<Map<String, Object>> before = new ArrayList<>();
            for (Map<String, Object> r : allLogs) {
                Object t=r.get("createTime");
                if (t!=null&&tt!=null&&String.valueOf(t).compareTo(String.valueOf(tt))<0) before.add(r);
            }
            List<Integer> ranked = evaluateRanking(uid,fid,tid,before,new double[]{-2,0,0}); // -2 triggers popularity
            if (ranked==null||ranked.isEmpty()) continue;
            if (Objects.equals(ranked.get(0),tid)) top1++;
            for (int k=0;k<Math.min(3,ranked.size());k++) if(Objects.equals(ranked.get(k),tid)){top3++;break;}
            for (int k=0;k<Math.min(5,ranked.size());k++) if(Objects.equals(ranked.get(k),tid)){top5++;break;}
            for (int k=0;k<Math.min(10,ranked.size());k++) if(Objects.equals(ranked.get(k),tid)){top10++;break;}
            for (int r=0;r<ranked.size();r++) if(Objects.equals(ranked.get(r),tid)){mrr+=1.0/(r+1);break;}
        }
        return new int[]{top1,top3,top5,top10,(int)Math.round(mrr*10000)};
    }

    /**
     * 菜品口味标签相似度分析：统计候选菜品之间的标签重叠度，
     * 用于讨论 PMFUP 在候选池有限时的优势边界。
     */
    /**
     * Bootstrap 重采样评测：从 86 用户中重采样到 200/500/1000 人规模，
     * 对比自适应与固定权重的性能差距是否随规模扩大而收敛。
     * 用于验证"自适应机制随数据增长而改善"的趋势。
     */
    @GetMapping("/recommendation/evaluate/bootstrap")
    public Result<Map<String, Object>> evaluateBootstrap() {
        List<Map<String, Object>> allLogs = recommendationMapper.listRecentLogs(HISTORY_WINDOW_DAYS, 5000);
        if (allLogs == null || allLogs.size() < 30) return Result.error("日志数量不足");

        // 按用户分组日志
        Map<Integer, List<Map<String, Object>>> userLogs = new LinkedHashMap<>();
        for (Map<String, Object> row : allLogs) {
            Integer uid = parseInt(row.get("userId"));
            if (uid != null) userLogs.computeIfAbsent(uid, k -> new ArrayList<>()).add(row);
        }
        List<Integer> userIds = new ArrayList<>(userLogs.keySet());
        Random rng = new Random(42);

        int[] sizes = {200, 500, 1000};
        Map<String, Object> result = new HashMap<>();
        result.put("baseUserCount", userIds.size());
        List<Map<String, Object>> scaleResults = new ArrayList<>();

        for (int size : sizes) {
            // Bootstrap 重采样
            List<Map<String, Object>> bootLogs = new ArrayList<>();
            for (int i = 0; i < size; i++) {
                int idx = rng.nextInt(userIds.size());
                bootLogs.addAll(userLogs.get(userIds.get(idx)));
            }

            bootLogs.sort((a, b) -> {
                Object ta = a.get("createTime"), tb = b.get("createTime");
                if (ta == null && tb == null) return 0;
                if (ta == null) return -1; if (tb == null) return 1;
                return String.valueOf(ta).compareTo(String.valueOf(tb));
            });

            List<Map<String, Object>> manual = new ArrayList<>();
            for (Map<String, Object> row : bootLogs) {
                String fb = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
                if (fb.startsWith("MANUAL_SELECTED")) manual.add(row);
            }
            int splitIdx = Math.max(1, (int) (manual.size() * 0.8));
            List<Map<String, Object>> test = manual.subList(splitIdx, manual.size());
            if (test.size() < 5) test = manual.subList(Math.max(0, manual.size() - 5), manual.size());

            double[] fixedW = {0.60, 0.25, 0.15};
            int[] fm = runEvalOnLogs(bootLogs, test, fixedW);
            int[] am = runEvalOnLogs(bootLogs, test, null);
            int tsz = test.size();

            Map<String, Object> row = new HashMap<>();
            row.put("bootSize", size);
            row.put("testSize", tsz);
            row.put("fixedTop1", tsz > 0 ? String.format("%.1f%%", 100.0*fm[0]/tsz) : "N/A");
            row.put("adaptiveTop1", tsz > 0 ? String.format("%.1f%%", 100.0*am[0]/tsz) : "N/A");
            row.put("top1Gap", tsz > 0 ? String.format("%+.1f%%", 100.0*(am[0]-fm[0])/tsz) : "N/A");
            row.put("fixedTop3", tsz > 0 ? String.format("%.1f%%", 100.0*fm[1]/tsz) : "N/A");
            row.put("adaptiveTop3", tsz > 0 ? String.format("%.1f%%", 100.0*am[1]/tsz) : "N/A");
            row.put("top3Gap", tsz > 0 ? String.format("%+.1f%%", 100.0*(am[1]-fm[1])/tsz) : "N/A");
            scaleResults.add(row);
        }

        result.put("scales", scaleResults);
        return Result.success(result);
    }

    /** 诊断接口：打印评测的中间状态，定位全零问题 */
    @GetMapping("/recommendation/evaluate/debug")
    public Result<Map<String, Object>> evaluateDebug() {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> allLogs = recommendationMapper.listRecentLogs(HISTORY_WINDOW_DAYS, 5000);

        // 统计日志来源
        Set<Integer> allUserIds = new HashSet<>();
        int manualCount = 0, hasFlightId = 0;
        Map<Integer, Integer> flightIdCounts = new HashMap<>();
        for (Map<String, Object> row : allLogs) {
            Integer uid = parseInt(row.get("userId"));
            Integer fid = parseInt(row.get("flightId"));
            if (uid != null) allUserIds.add(uid);
            String fb = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
            if (fb.startsWith("MANUAL_SELECTED")) {
                manualCount++;
                if (fid != null) {
                    hasFlightId++;
                    flightIdCounts.merge(fid, 1, Integer::sum);
                }
            }
        }
        result.put("totalLogs", allLogs.size());
        result.put("totalUserIds", allUserIds.size());
        result.put("manualLogs", manualCount);
        result.put("manualWithFlightId", hasFlightId);
        result.put("flightIdDistribution", flightIdCounts);

        // 跑一条 MANUAL_SELECTED 日志的单步诊断
        Map<String, Object> testLog = null;
        for (Map<String, Object> row : allLogs) {
            String fb = row.get("userFeedback") == null ? "" : String.valueOf(row.get("userFeedback"));
            if (fb.startsWith("MANUAL_SELECTED")) {
                Integer fid = parseInt(row.get("flightId"));
                if (fid != null) { testLog = row; break; }
            }
        }
        if (testLog != null) {
            Integer uid = parseInt(testLog.get("userId"));
            Integer fid = parseInt(testLog.get("flightId"));
            Integer tid = extractDishIdFromText(testLog.get("userFeedback"));
            result.put("sampleUserId", uid);
            result.put("sampleFlightId", fid);
            result.put("sampleDishId", tid);

            FlightInfo fi = flightInfoMapper.getById(fid);
            result.put("flightExists", fi != null);
            if (fi != null) {
                result.put("flightNumber", fi.getFlightNumber());
                result.put("flightDeparture", fi.getDeparture());
                result.put("flightDestination", fi.getDestination());
                List<Integer> cts = resolveCabinTypes(fi, uid);
                result.put("cabinTypes", cts);
                List<RecommendationDishVO> candidates = recommendationMapper.listCandidateDishes(fid, null, null, 10, cts);
                result.put("candidateCount", candidates.size());
                if (!candidates.isEmpty()) {
                    List<String> dishNames = new ArrayList<>();
                    for (RecommendationDishVO d : candidates) {
                        if (d.getDishName() != null) dishNames.add(d.getDishName());
                    }
                    result.put("candidateDishes", dishNames.subList(0, Math.min(5, dishNames.size())));
                    result.put("truthInCandidates", candidates.stream().anyMatch(d -> Objects.equals(d.getDishId(), tid)));
                }
            }
        }
        return Result.success(result);
    }

    @GetMapping("/recommendation/dish-similarity")
    public Result<Map<String, Object>> dishSimilarity() {
        // 取所有启用且有库存的菜品
        List<RecommendationDishVO> dishes = recommendationMapper.listCandidateDishes(
                null, null, null, 50, Arrays.asList(CABIN_FIRST, CABIN_BUSINESS, CABIN_ECONOMY));
        if (dishes == null || dishes.size() < 2) return Result.error("菜品数量不足");

        // 统计每道菜品的口味标签
        Map<String, Set<String>> dishTags = new LinkedHashMap<>();
        for (RecommendationDishVO d : dishes) {
            if (d.getDishName() == null || d.getFlavorTags() == null) continue;
            Set<String> tags = parseFlavorTokens(d.getFlavorTags());
            if (!tags.isEmpty()) dishTags.put(d.getDishName(), tags);
        }

        // 计算两两之间的 Jaccard 相似度和重叠标签
        List<Map<String, Object>> pairs = new ArrayList<>();
        List<String> names = new ArrayList<>(dishTags.keySet());
        double totalOverlap = 0;
        int pairCount = 0;
        for (int i = 0; i < names.size(); i++) {
            for (int j = i + 1; j < names.size(); j++) {
                Set<String> a = dishTags.get(names.get(i));
                Set<String> b = dishTags.get(names.get(j));
                Set<String> overlap = new HashSet<>(a);
                overlap.retainAll(b);
                Set<String> union = new HashSet<>(a);
                union.addAll(b);
                double jaccard = union.isEmpty() ? 0 : (double) overlap.size() / union.size();
                totalOverlap += overlap.size();
                pairCount++;
                Map<String, Object> pair = new HashMap<>();
                pair.put("dishA", names.get(i)); pair.put("dishB", names.get(j));
                pair.put("tagsA", String.join(",", a)); pair.put("tagsB", String.join(",", b));
                pair.put("overlapCount", overlap.size());
                pair.put("jaccard", String.format("%.2f", jaccard));
                pairs.add(pair);
            }
        }

        // 统计有多少菜品有唯一标签组合
        Set<String> uniqueCombos = new HashSet<>();
        int dupCount = 0;
        for (String name : names) {
            String combo = String.join(",", new TreeSet<>(dishTags.get(name)));
            if (!uniqueCombos.add(combo)) dupCount++;
        }

        Map<String, Object> result = new HashMap<>();
        result.put("totalDishes", names.size());
        result.put("totalPairs", pairCount);
        result.put("avgOverlapPerPair", pairCount > 0 ? String.format("%.2f", totalOverlap / pairCount) : "0");
        result.put("uniqueTagCombos", uniqueCombos.size());
        result.put("dishesSharingCombo", dupCount);
        result.put("note", uniqueCombos.size() < names.size()
                ? "存在标签组合完全相同的菜品，PMFUP 无法区分这些菜品的优劣"
                : "每道菜品标签组合互不相同，PMFUP 在口味维度上可区分所有菜品");
        result.put("pairs", pairs);
        return Result.success(result);
    }

    @GetMapping("/announcement/list")
    public Result<List<FlightAnnouncement>> announcementList() {
        Integer userId = BaseContext.getCurrentId();
        User user = userMapper.getById(userId);
        Integer flightId = user != null ? user.getCurrentFlightId() : null;
        return Result.success(announcementMapper.list(flightId));
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

    private String validatePreference(String mealTypePreferences, String flavorPreferences) {
        if (mealTypePreferences == null && flavorPreferences == null) {
            return "偏好参数不能为空";
        }
        Set<Integer> mealTypes = parsePreferenceMealTypes(mealTypePreferences);
        for (Integer mt : mealTypes) {
            if (!ALLOWED_MEAL_TYPES.contains(mt)) {
                return "mealTypePreferences包含非法餐型";
            }
        }
        List<String> flavors = parseFlavorList(flavorPreferences);
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
        recommendLog.put("userFeedback", event + ":dishId=" + dishId + ":mealOrder=" + mealOrder);
        recommendationMapper.insertLog(recommendLog);
    }

    private void insertClickLog(Integer userId, Integer flightId, Integer dishId, Integer mealOrder) {
        Map<String, Object> recommendLog = new HashMap<>();
        recommendLog.put("userId", userId);
        recommendLog.put("flightId", flightId);
        recommendLog.put("recommendedDishes", "[" + dishId + "]");
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
                if (flightId == null) {
                    continue;
                }

                Map<String, Object> params = new HashMap<>();
                params.put("userId", userId);
                params.put("flightId", flightId);
                params.put("ratingStatus", RATING_STATUS_PENDING);
                params.put("firstVisibleAt", now);
                params.put("lastVisibleAt", now);
                params.put("nextRemindAt", now);
                params.put("deferCount", 0);
                params.put("expireAt", now.plusDays(RATING_EXPIRE_DAYS));
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
