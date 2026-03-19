package fun.hykgraph.controller.user;

import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.vo.PendingRatingInfoVO;
import fun.hykgraph.vo.RecommendationDishVO;
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
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RecommendationControllerTest {

    @Mock
    private RecommendationMapper recommendationMapper;

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
}
