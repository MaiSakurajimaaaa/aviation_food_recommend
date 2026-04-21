package fun.hykgraph.controller.admin;

import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.result.Result;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AnnouncementControllerTest {

    @Mock
    private RecommendationMapper recommendationMapper;

    @Test
    void ratingList_shouldMarkPendingTaskAsExpiredWhenExpireAtHasPassed() {
        AnnouncementController controller = new AnnouncementController();
        ReflectionTestUtils.setField(controller, "recommendationMapper", recommendationMapper);

        List<Map<String, Object>> tasks = new ArrayList<>();

        Map<String, Object> expiredButPending = new HashMap<>();
        expiredButPending.put("id", 1L);
        expiredButPending.put("ratingStatus", "PENDING");
        expiredButPending.put("expireAt", LocalDateTime.now().minusMinutes(5));
        tasks.add(expiredButPending);

        Map<String, Object> stillPending = new HashMap<>();
        stillPending.put("id", 2L);
        stillPending.put("ratingStatus", "PENDING");
        stillPending.put("expireAt", LocalDateTime.now().plusMinutes(5));
        tasks.add(stillPending);

        when(recommendationMapper.ratingTaskList(null, null, null)).thenReturn(tasks);

        Result<List<Map<String, Object>>> result = controller.ratingList(null, null, null);

        assertNotNull(result);
        assertNotNull(result.getData());
        assertEquals("EXPIRED", result.getData().get(0).get("ratingStatus"));
        assertEquals("PENDING", result.getData().get(1).get("ratingStatus"));
    }

    @Test
    void ratingList_shouldFilterByNormalizedStatusAfterStandardizingTaskStatus() {
        AnnouncementController controller = new AnnouncementController();
        ReflectionTestUtils.setField(controller, "recommendationMapper", recommendationMapper);

        List<Map<String, Object>> tasks = new ArrayList<>();

        Map<String, Object> expiredButDeferred = new HashMap<>();
        expiredButDeferred.put("id", 1L);
        expiredButDeferred.put("ratingStatus", "DEFERRED");
        expiredButDeferred.put("expireAt", LocalDateTime.now().minusMinutes(1));
        tasks.add(expiredButDeferred);

        Map<String, Object> explicitExpired = new HashMap<>();
        explicitExpired.put("id", 2L);
        explicitExpired.put("ratingStatus", "EXPIRED");
        explicitExpired.put("expireAt", LocalDateTime.now().minusMinutes(10));
        tasks.add(explicitExpired);

        Map<String, Object> stillPending = new HashMap<>();
        stillPending.put("id", 3L);
        stillPending.put("ratingStatus", "PENDING");
        stillPending.put("expireAt", LocalDateTime.now().plusMinutes(10));
        tasks.add(stillPending);

        when(recommendationMapper.ratingTaskList(null, "MU", "张")).thenReturn(tasks);

        Result<List<Map<String, Object>>> result = controller.ratingList("EXPIRED", " MU ", " 张 ");

        assertNotNull(result);
        assertNotNull(result.getData());
        assertEquals(2, result.getData().size());
        assertEquals("EXPIRED", result.getData().get(0).get("ratingStatus"));
        assertEquals("EXPIRED", result.getData().get(1).get("ratingStatus"));
        verify(recommendationMapper).ratingTaskList(null, "MU", "张");
    }

    @Test
    void ratingDashboard_shouldUseNormalizedStatusForCounts() {
        AnnouncementController controller = new AnnouncementController();
        ReflectionTestUtils.setField(controller, "recommendationMapper", recommendationMapper);

        List<Map<String, Object>> tasks = new ArrayList<>();

        Map<String, Object> expiredButPending = new HashMap<>();
        expiredButPending.put("id", 1L);
        expiredButPending.put("ratingStatus", "PENDING");
        expiredButPending.put("expireAt", LocalDateTime.now().minusMinutes(1));
        tasks.add(expiredButPending);

        Map<String, Object> deferred = new HashMap<>();
        deferred.put("id", 2L);
        deferred.put("ratingStatus", "DEFERRED");
        deferred.put("expireAt", LocalDateTime.now().plusMinutes(10));
        tasks.add(deferred);

        Map<String, Object> submitted = new HashMap<>();
        submitted.put("id", 3L);
        submitted.put("ratingStatus", "SUBMITTED");
        submitted.put("ratingScore", 4);
        submitted.put("expireAt", LocalDateTime.now().minusMinutes(20));
        tasks.add(submitted);

        Map<String, Object> explicitExpired = new HashMap<>();
        explicitExpired.put("id", 4L);
        explicitExpired.put("ratingStatus", "EXPIRED");
        explicitExpired.put("expireAt", LocalDateTime.now().minusMinutes(30));
        tasks.add(explicitExpired);

        when(recommendationMapper.ratingTaskList(null, null, null)).thenReturn(tasks);

        Result<Map<String, Object>> result = controller.ratingDashboard();

        assertNotNull(result);
        assertNotNull(result.getData());
        assertEquals(4, Number.class.cast(result.getData().get("totalCount")).intValue());
        assertEquals(0, Number.class.cast(result.getData().get("pendingCount")).intValue());
        assertEquals(1, Number.class.cast(result.getData().get("deferredCount")).intValue());
        assertEquals(1, Number.class.cast(result.getData().get("submittedCount")).intValue());
        assertEquals(2, Number.class.cast(result.getData().get("expiredCount")).intValue());
        assertEquals(4.0, Number.class.cast(result.getData().get("avgScore")).doubleValue());
        assertEquals(25.0, Number.class.cast(result.getData().get("submitRate")).doubleValue());
        verify(recommendationMapper).ratingTaskList(null, null, null);
    }
}
