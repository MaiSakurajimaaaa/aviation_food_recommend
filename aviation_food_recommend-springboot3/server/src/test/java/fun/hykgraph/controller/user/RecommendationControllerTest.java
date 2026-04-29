package fun.hykgraph.controller.user;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.entity.User;
import fun.hykgraph.mapper.DishMapper;
import fun.hykgraph.mapper.FlightInfoMapper;
import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.mapper.UserMapper;
import fun.hykgraph.mapper.UserPreferenceMapper;
import fun.hykgraph.result.Result;
import fun.hykgraph.vo.PendingRatingInfoVO;
import fun.hykgraph.vo.RecommendationDishVO;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RecommendationControllerTest {

    @Mock
    private RecommendationMapper recommendationMapper;
        @Mock
        private UserMapper userMapper;
        @Mock
        private FlightInfoMapper flightInfoMapper;
        @Mock
        private UserPreferenceMapper userPreferenceMapper;
        @Mock
        private DishMapper dishMapper;

        @AfterEach
        void tearDown() {
                BaseContext.removeCurrentId();
        }

        @Test
        void list_shouldPassUserCabinTypeToCandidateQuery() {
                RecommendationController controller = createControllerWithDependencies();
                BaseContext.setCurrentId(7);

                User user = User.builder()
                                .id(7)
                                .currentFlightId(100)
                                .cabinType(2)
                                .build();
                FlightInfo flightInfo = new FlightInfo();
                flightInfo.setId(100);
                flightInfo.setMealCount(2);

                when(userMapper.getById(7)).thenReturn(user);
                when(flightInfoMapper.getById(100)).thenReturn(flightInfo);
                when(recommendationMapper.listCandidateDishes(100, null, null, 10, Arrays.asList(2, 3))).thenReturn(Collections.emptyList());

                Result<List<RecommendationDishVO>> result = controller.list(null, null, 1, 10);

                assertNotNull(result);
                assertEquals(0, result.getCode());
                verify(recommendationMapper, times(1)).listCandidateDishes(100, null, null, 10, Arrays.asList(2, 3));
        }

        @Test
        void list_shouldFallbackToEconomyCabinWhenCabinTypeMissing() {
                RecommendationController controller = createControllerWithDependencies();
                BaseContext.setCurrentId(8);

                User user = User.builder()
                                .id(8)
                                .currentFlightId(101)
                                .build();
                FlightInfo flightInfo = new FlightInfo();
                flightInfo.setId(101);
                flightInfo.setMealCount(1);

                when(userMapper.getById(8)).thenReturn(user);
                when(flightInfoMapper.getById(101)).thenReturn(flightInfo);
                when(recommendationMapper.listCandidateDishes(101, null, null, 10, Arrays.asList(3))).thenReturn(Collections.emptyList());

                Result<List<RecommendationDishVO>> result = controller.list(null, null, 1, 10);

                assertNotNull(result);
                assertEquals(0, result.getCode());
                verify(recommendationMapper, times(1)).listCandidateDishes(101, null, null, 10, Arrays.asList(3));
        }

        @Test
        void list_shouldUseCascadeCabinSetForFirstClass() {
                RecommendationController controller = createControllerWithDependencies();
                BaseContext.setCurrentId(9);

                User user = User.builder()
                                .id(9)
                                .currentFlightId(102)
                                .cabinType(1)
                                .build();
                FlightInfo flightInfo = new FlightInfo();
                flightInfo.setId(102);
                flightInfo.setMealCount(2);

                when(userMapper.getById(9)).thenReturn(user);
                when(flightInfoMapper.getById(102)).thenReturn(flightInfo);
                when(recommendationMapper.listCandidateDishes(102, null, null, 10, Arrays.asList(1, 2, 3))).thenReturn(Collections.emptyList());

                Result<List<RecommendationDishVO>> result = controller.list(null, null, 1, 10);

                assertNotNull(result);
                assertEquals(0, result.getCode());
                verify(recommendationMapper, times(1)).listCandidateDishes(102, null, null, 10, Arrays.asList(1, 2, 3));
        }

    @Test
    void extractDishIdFromText_shouldParseFirstDishIdInsteadOfConcatenatingDigits() throws Exception {
        RecommendationController controller = new RecommendationController();

        Method method = RecommendationController.class.getDeclaredMethod("extractDishIdFromText", Object.class);
        method.setAccessible(true);

        Integer parsed = (Integer) method.invoke(controller, "[12,5]");

        assertEquals(12, parsed);
    }

    @Test
    void resolvePendingRatings_shouldSeedTasksEvenWhenVisibleTaskAlreadyExists() throws Exception {
        RecommendationController controller = new RecommendationController();
        ReflectionTestUtils.setField(controller, "recommendationMapper", recommendationMapper);

        Integer userId = 7;
        LocalDateTime now = LocalDateTime.of(2026, 3, 18, 10, 0);

        PendingRatingInfoVO existing = new PendingRatingInfoVO();
        existing.setFlightId(100);
        List<PendingRatingInfoVO> visible = new ArrayList<>();
        visible.add(existing);

        PendingRatingInfoVO mergedA = new PendingRatingInfoVO();
        mergedA.setFlightId(100);
        PendingRatingInfoVO mergedB = new PendingRatingInfoVO();
        mergedB.setFlightId(200);
        List<PendingRatingInfoVO> merged = new ArrayList<>();
        merged.add(mergedA);
        merged.add(mergedB);

        Map<String, Object> seed = new HashMap<>();
        seed.put("flightId", 200);
        seed.put("sourceLogId", 99L);
        List<Map<String, Object>> seeds = new ArrayList<>();
        seeds.add(seed);

        when(recommendationMapper.findVisiblePendingRatings(eq(userId), any(LocalDateTime.class)))
                .thenReturn(visible)
                .thenReturn(merged);
        when(recommendationMapper.findEndedManualSelectionsWithoutRating(eq(userId), any(LocalDateTime.class)))
                .thenReturn(seeds);

        Method method = RecommendationController.class.getDeclaredMethod("resolvePendingRatings", Integer.class, LocalDateTime.class);
        method.setAccessible(true);

        @SuppressWarnings("unchecked")
        List<PendingRatingInfoVO> result = (List<PendingRatingInfoVO>) method.invoke(controller, userId, now);

        assertNotNull(result);
        assertEquals(2, result.size());
        verify(recommendationMapper, times(1))
                .findEndedManualSelectionsWithoutRating(eq(userId), eq(now));
        verify(recommendationMapper, times(1))
                .upsertFlightRatingTask(ArgumentMatchers.anyMap());
    }

        @Test
        void calculatePmfupScore_shouldNotDependOnRouteFields() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                Method method = RecommendationController.class.getDeclaredMethod(
                        "calculatePmfupScore",
                        RecommendationDishVO.class,
                        Integer.class,
                        java.util.Set.class,
                        Integer.class,
                        contextClass,
                        Integer.class,
                        LocalDateTime.class,
                        Integer.class
                );
                method.setAccessible(true);

                RecommendationDishVO withoutRoute = new RecommendationDishVO();
                withoutRoute.setDishId(11);
                withoutRoute.setDishName("清汤面");
                withoutRoute.setMealType(2);
                withoutRoute.setFlavorTags("清淡");

                RecommendationDishVO withRoute = new RecommendationDishVO();
                withRoute.setDishId(11);
                withRoute.setDishName("清汤面");
                withRoute.setMealType(2);
                withRoute.setFlavorTags("清淡");
                withRoute.setRouteDeparture("北京");
                withRoute.setRouteDestination("上海");

                LocalDateTime departure = LocalDateTime.of(2026, 3, 18, 7, 30);
                Double scoreWithoutRoute = (Double) method.invoke(controller, withoutRoute, null, Collections.emptySet(), 100, context, 7, departure, 1);
                Double scoreWithRoute = (Double) method.invoke(controller, withRoute, null, Collections.emptySet(), 100, context, 7, departure, 1);

                assertEquals(scoreWithoutRoute, scoreWithRoute);
        }

        @Test
        void calculatePmfupScore_shouldIgnoreTimeAndAssociationSignals() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                @SuppressWarnings("unchecked")
                Map<Integer, Map<Integer, Double>> userDishScore =
                        (Map<Integer, Map<Integer, Double>>) ReflectionTestUtils.getField(context, "userDishScore");

                Map<Integer, Double> profile = new HashMap<>();
                profile.put(9, 10.0);
                userDishScore.put(7, profile);

                Method method = RecommendationController.class.getDeclaredMethod(
                        "calculatePmfupScore",
                        RecommendationDishVO.class,
                        Integer.class,
                        java.util.Set.class,
                        Integer.class,
                        contextClass,
                        Integer.class,
                        LocalDateTime.class,
                        Integer.class
                );
                method.setAccessible(true);

                RecommendationDishVO dish = new RecommendationDishVO();
                dish.setDishId(11);
                dish.setDishName("清汤面");
                dish.setMealType(1);
                dish.setFlavorTags("清淡");

                Double earlyScore = (Double) method.invoke(
                        controller,
                        dish,
                        1,
                        Collections.singleton("清淡"),
                        100,
                        context,
                        7,
                        LocalDateTime.of(2026, 3, 18, 7, 0),
                        1
                );
                Double lateScore = (Double) method.invoke(
                        controller,
                        dish,
                        1,
                        Collections.singleton("清淡"),
                        100,
                        context,
                        7,
                        LocalDateTime.of(2026, 3, 18, 20, 0),
                        1
                );

                assertEquals(earlyScore, lateScore);
        }

            @Test
            void calculateTimePreferenceScore_shouldPreferBreakfastWhenEarly() throws Exception {
                RecommendationController controller = new RecommendationController();

                Method method = RecommendationController.class.getDeclaredMethod("calculateTimePreferenceScore", Integer.class, LocalTime.class);
                method.setAccessible(true);

                Double breakfastEarly = (Double) method.invoke(controller, 1, LocalTime.of(7, 30));
                Double breakfastLate = (Double) method.invoke(controller, 1, LocalTime.of(20, 0));
                Double standardEarly = (Double) method.invoke(controller, 2, LocalTime.of(7, 30));

                assertTrue(breakfastEarly > breakfastLate);
                assertTrue(breakfastEarly > standardEarly);
            }

            @Test
            void calculateTimePreferenceScore_shouldBiasBreakfastSeriesForFirstMealOnEarlyFlight() throws Exception {
                RecommendationController controller = new RecommendationController();

                Method method = RecommendationController.class.getDeclaredMethod(
                        "calculateTimePreferenceScore",
                        RecommendationDishVO.class,
                        LocalDateTime.class,
                        Integer.class
                );
                method.setAccessible(true);

                RecommendationDishVO breakfastDish = new RecommendationDishVO();
                breakfastDish.setDishId(101);
                breakfastDish.setDishName("鲜虾粥");
                breakfastDish.setMealType(2);

                RecommendationDishVO nonBreakfastDish = new RecommendationDishVO();
                nonBreakfastDish.setDishId(102);
                nonBreakfastDish.setDishName("黑椒牛肉饭");
                nonBreakfastDish.setMealType(2);

                LocalDateTime earlyDeparture = LocalDateTime.of(2026, 3, 18, 7, 0);
                Double breakfastScore = (Double) method.invoke(controller, breakfastDish, earlyDeparture, 1);
                Double nonBreakfastScore = (Double) method.invoke(controller, nonBreakfastDish, earlyDeparture, 1);

                assertTrue(breakfastScore > nonBreakfastScore);
            }

            @Test
            void calculateAmmbcScore_shouldNotUseAssociationOnlySignal() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                @SuppressWarnings("unchecked")
                Map<Integer, Map<Integer, Double>> userDishScore =
                        (Map<Integer, Map<Integer, Double>>) ReflectionTestUtils.getField(context, "userDishScore");

                Map<Integer, Double> selfVector = new HashMap<>();
                selfVector.put(9, 6.0);
                userDishScore.put(7, selfVector);

                Method method = RecommendationController.class.getDeclaredMethod(
                        "calculateAmmbcScore",
                        Integer.class,
                        Integer.class,
                        contextClass
                );
                method.setAccessible(true);

                Double score = (Double) method.invoke(controller, 7, 11, context);

                assertEquals(0.0, score);
            }

        @Test
        void resolveFusionWeights_shouldPreferPmfupWhenBehaviorSignalsSparse() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                @SuppressWarnings("unchecked")
                Map<Integer, Integer> signalMap = (Map<Integer, Integer>) ReflectionTestUtils.getField(context, "userBehaviorSignal");
                signalMap.put(7, 1);

                Method method = RecommendationController.class.getDeclaredMethod("resolveFusionWeights", Integer.class, contextClass);
                method.setAccessible(true);

                double[] weights = (double[]) method.invoke(controller, 7, context);

                assertEquals(1.0, weights[0] + weights[1] + weights[2], 1e-6);
                assertTrue(weights[0] > weights[1]);
                assertTrue(weights[1] > weights[2]);
        }

        @Test
        void resolveFusionWeights_shouldKeepDefaultWhenBehaviorSignalsRich() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                @SuppressWarnings("unchecked")
                Map<Integer, Integer> signalMap = (Map<Integer, Integer>) ReflectionTestUtils.getField(context, "userBehaviorSignal");
                signalMap.put(7, 10);

                Method method = RecommendationController.class.getDeclaredMethod("resolveFusionWeights", Integer.class, contextClass);
                method.setAccessible(true);

                double[] weights = (double[]) method.invoke(controller, 7, context);

                assertEquals(1.0, weights[0] + weights[1] + weights[2], 1e-6);
                assertTrue(weights[2] >= weights[1]);
                assertTrue(weights[2] > 0.25);
        }

        @Test
        void resolveFusionWeights_shouldChangeSmoothlyWithSignalGrowth() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                @SuppressWarnings("unchecked")
                Map<Integer, Integer> signalMap = (Map<Integer, Integer>) ReflectionTestUtils.getField(context, "userBehaviorSignal");
                Method method = RecommendationController.class.getDeclaredMethod("resolveFusionWeights", Integer.class, contextClass);
                method.setAccessible(true);

                signalMap.put(7, 3);
                double[] weightsAtThree = (double[]) method.invoke(controller, 7, context);

                signalMap.put(7, 4);
                double[] weightsAtFour = (double[]) method.invoke(controller, 7, context);

                assertTrue(Math.abs(weightsAtThree[0] - weightsAtFour[0]) > 1e-6);
                assertTrue(Math.abs(weightsAtThree[1] - weightsAtFour[1]) > 1e-6);
                assertTrue(Math.abs(weightsAtThree[2] - weightsAtFour[2]) > 1e-6);
        }

        @Test
        void buildInteractionContext_shouldKeepSignalsForNonCandidateDishes() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");

                Method buildMethod = RecommendationController.class.getDeclaredMethod(
                        "buildInteractionContext",
                        List.class,
                        Map.class,
                        Map.class
                );
                buildMethod.setAccessible(true);

                List<Map<String, Object>> logs = new ArrayList<>();
                Map<String, Object> row = new HashMap<>();
                row.put("userId", 7);
                row.put("recommendedDishes", "[999]");
                row.put("userFeedback", "MANUAL_SELECTED:dishId=999:mealOrder=1");
                row.put("createTime", LocalDateTime.now().minusDays(2));
                logs.add(row);

                Map<Integer, RecommendationDishVO> candidateMap = new HashMap<>();
                RecommendationDishVO candidateDish = new RecommendationDishVO();
                candidateDish.setDishId(11);
                candidateDish.setFlavorTags("清淡");
                candidateMap.put(11, candidateDish);

                Object context = buildMethod.invoke(controller, logs, candidateMap, new HashMap<String, Integer>());

                @SuppressWarnings("unchecked")
                Map<Integer, Map<Integer, Double>> userDishScore =
                        (Map<Integer, Map<Integer, Double>>) ReflectionTestUtils.getField(context, "userDishScore");

                assertTrue(userDishScore.containsKey(7));
                assertTrue(userDishScore.get(7).containsKey(999));
        }

        @Test
        void buildInteractionContext_shouldCountBehaviorSignalOncePerLog() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");

                Method buildMethod = RecommendationController.class.getDeclaredMethod(
                        "buildInteractionContext",
                        List.class,
                        Map.class,
                        Map.class
                );
                buildMethod.setAccessible(true);

                Method signalMethod = RecommendationController.class.getDeclaredMethod(
                        "resolveBehaviorSignalCount",
                        Integer.class,
                        contextClass
                );
                signalMethod.setAccessible(true);

                List<Map<String, Object>> logs = new ArrayList<>();
                Map<String, Object> row = new HashMap<>();
                row.put("userId", 7);
                row.put("recommendedDishes", "[11]");
                row.put("userFeedback", "MANUAL_SELECTED:dishId=11:mealOrder=1");
                row.put("userRating", 5);
                row.put("createTime", LocalDateTime.now().minusDays(1));
                logs.add(row);

                Map<Integer, RecommendationDishVO> candidateMap = new HashMap<>();
                RecommendationDishVO candidateDish = new RecommendationDishVO();
                candidateDish.setDishId(11);
                candidateDish.setFlavorTags("微辣");
                candidateMap.put(11, candidateDish);

                Object context = buildMethod.invoke(controller, logs, candidateMap, new HashMap<String, Integer>());

                int signalCount = (int) signalMethod.invoke(controller, 7, context);
                assertEquals(1, signalCount);
        }

        @Test
        void calculatePrmidmScore_shouldPreferRecentFlavorDriftMatch() throws Exception {
                RecommendationController controller = new RecommendationController();

                Class<?> contextClass = Class.forName("fun.hykgraph.controller.user.RecommendationController$InteractionContext");
                Constructor<?> ctor = contextClass.getDeclaredConstructor();
                ctor.setAccessible(true);
                Object context = ctor.newInstance();

                @SuppressWarnings("unchecked")
                Map<Integer, Set<String>> dishFlavorTags =
                        (Map<Integer, Set<String>>) ReflectionTestUtils.getField(context, "dishFlavorTags");
                @SuppressWarnings("unchecked")
                Map<Integer, Map<String, Double>> userRecentFlavorScore =
                        (Map<Integer, Map<String, Double>>) ReflectionTestUtils.getField(context, "userRecentFlavorScore");
                @SuppressWarnings("unchecked")
                Map<Integer, Map<String, Double>> userLongFlavorScore =
                        (Map<Integer, Map<String, Double>>) ReflectionTestUtils.getField(context, "userLongFlavorScore");

                dishFlavorTags.put(11, Collections.singleton("微辣"));

                Map<String, Double> recent = new HashMap<>();
                recent.put("微辣", 4.0);
                userRecentFlavorScore.put(7, recent);

                Map<String, Double> longTerm = new HashMap<>();
                longTerm.put("微辣", 1.0);
                userLongFlavorScore.put(7, longTerm);

                Method method = RecommendationController.class.getDeclaredMethod(
                        "calculatePrmidmScore",
                        Integer.class,
                        Integer.class,
                        contextClass
                );
                method.setAccessible(true);

                Double driftMatched = (Double) method.invoke(controller, 7, 11, context);

                recent.put("微辣", 0.2);
                longTerm.put("微辣", 2.4);

                Double driftMismatched = (Double) method.invoke(controller, 7, 11, context);

                assertTrue(driftMatched > driftMismatched);
        }

                        @Test
                        void insertClickLog_shouldWriteClickFeedbackWithDishAndMealOrder() throws Exception {
                                RecommendationController controller = new RecommendationController();
                                ReflectionTestUtils.setField(controller, "recommendationMapper", recommendationMapper);

                                Method method = RecommendationController.class.getDeclaredMethod(
                                                "insertClickLog",
                                                Integer.class,
                                                Integer.class,
                                                Integer.class,
                                                Integer.class
                                );
                                method.setAccessible(true);

                                method.invoke(controller, 7, 100, 11, 2);

                                verify(recommendationMapper, times(1)).insertLog(argThat(params -> {
                                        Object feedback = params.get("userFeedback");
                                        Object dishes = params.get("recommendedDishes");
                                        return feedback != null
                                                        && String.valueOf(feedback).startsWith("CLICK:dishId=11:mealOrder=2")
                                                        && "[11]".equals(String.valueOf(dishes));
                                }));
                        }

        private RecommendationController createControllerWithDependencies() {
                RecommendationController controller = new RecommendationController();
                ReflectionTestUtils.setField(controller, "recommendationMapper", recommendationMapper);
                ReflectionTestUtils.setField(controller, "userMapper", userMapper);
                ReflectionTestUtils.setField(controller, "flightInfoMapper", flightInfoMapper);
                ReflectionTestUtils.setField(controller, "userPreferenceMapper", userPreferenceMapper);
                ReflectionTestUtils.setField(controller, "dishMapper", dishMapper);
                return controller;
        }
}
