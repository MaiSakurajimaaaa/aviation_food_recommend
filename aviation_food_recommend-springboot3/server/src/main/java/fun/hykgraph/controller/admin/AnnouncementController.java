package fun.hykgraph.controller.admin;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.entity.FlightAnnouncement;
import fun.hykgraph.mapper.FlightAnnouncementMapper;
import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.result.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/admin")
public class AnnouncementController {

    @Autowired
    private FlightAnnouncementMapper announcementMapper;
    @Autowired
    private RecommendationMapper recommendationMapper;

    @GetMapping("/announcement/list")
    public Result<List<FlightAnnouncement>> list(@RequestParam(required = false) Integer flightId) {
        return Result.success(announcementMapper.list(flightId));
    }

    @PostMapping("/announcement")
    public Result add(@RequestBody FlightAnnouncement announcement) {
        announcement.setStatus(announcement.getStatus() == null ? 1 : announcement.getStatus());
        announcement.setCreateUser(BaseContext.getCurrentId());

        announcement.setCreateTime(LocalDateTime.now());
        announcement.setUpdateTime(LocalDateTime.now());
        announcementMapper.insert(announcement);
        return Result.success();
    }

    @PutMapping("/announcement")
    public Result update(@RequestBody FlightAnnouncement announcement) {
        announcement.setUpdateTime(LocalDateTime.now());
        announcementMapper.update(announcement);
        return Result.success();
    }

    @DeleteMapping("/announcement/{id}")
    public Result delete(@PathVariable Integer id) {
        announcementMapper.deleteById(id);
        return Result.success();
    }

    @GetMapping("/recommendation/dashboard")
    public Result<Map<String, Object>> dashboard() {
        return Result.success(recommendationMapper.dashboard());
    }

    @GetMapping("/recommendation/top")
    public Result<List<Map<String, Object>>> top(@RequestParam(defaultValue = "8") Integer size,
                                                  @RequestParam(required = false) Integer days) {
        int safeSize = Math.max(1, Math.min(size, 30));
        LocalDateTime endTime = LocalDateTime.now();
        LocalDateTime startTime = null;
        if (days != null && days > 0) {
            startTime = endTime.minusDays(Math.min(days, 365));
        }
        return Result.success(recommendationMapper.topDishes(safeSize, startTime, endTime));
    }

    @GetMapping("/recommendation/exceptions")
    public Result<List<Map<String, Object>>> exceptionUsers() {
        return Result.success(recommendationMapper.exceptionUsers());
    }

    @GetMapping("/recommendation/rating/dashboard")
    public Result<Map<String, Object>> ratingDashboard() {
        List<Map<String, Object>> tasks = recommendationMapper.ratingTaskList(null, null, null);
        return Result.success(buildRatingDashboard(tasks, LocalDateTime.now()));
    }

    @GetMapping("/recommendation/rating/list")
    public Result<List<Map<String, Object>>> ratingList(@RequestParam(required = false) String status,
                                                         @RequestParam(required = false) String flightNumber,
                                                         @RequestParam(required = false) String userKeyword) {
        String normalizedStatus = normalizeStatus(status);
        String normalizedFlightNumber = safeTrim(flightNumber);
        String normalizedUserKeyword = safeTrim(userKeyword);
        LocalDateTime now = LocalDateTime.now();

        List<Map<String, Object>> tasks = recommendationMapper.ratingTaskList(null, normalizedFlightNumber, normalizedUserKeyword);
        return Result.success(normalizeRatingTasks(tasks, normalizedStatus, now));
    }

    @PostMapping("/recommendation/rating/{id}/reopen")
    public Result reopenRating(@PathVariable Long id) {
        Integer affected = recommendationMapper.reopenRatingTask(id, LocalDateTime.now());
        if (affected == null || affected <= 0) {
            return Result.error("评分任务不存在");
        }
        return Result.success();
    }

    @PostMapping("/recommendation/rating/{id}/expire")
    public Result expireRating(@PathVariable Long id) {
        Integer affected = recommendationMapper.expireRatingTask(id, LocalDateTime.now());
        if (affected == null || affected <= 0) {
            return Result.error("评分任务不存在");
        }
        return Result.success();
    }

    @DeleteMapping("/recommendation/rating/{id}")
    public Result deleteRating(@PathVariable Long id) {
        Integer affected = recommendationMapper.deleteRatingTask(id);
        if (affected == null || affected <= 0) {
            return Result.error("评分任务不存在");
        }
        return Result.success();
    }

    private String safeTrim(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private List<Map<String, Object>> normalizeRatingTasks(List<Map<String, Object>> tasks,
                                                           String statusFilter,
                                                           LocalDateTime now) {
        if (tasks == null || tasks.isEmpty()) {
            return Collections.emptyList();
        }
        List<Map<String, Object>> normalized = new ArrayList<>();
        for (Map<String, Object> task : tasks) {
            if (task == null) {
                continue;
            }
            normalizeRatingStatus(task, now);
            String taskStatus = normalizeStatus(asString(task.get("ratingStatus")));
            if (statusFilter == null || statusFilter.equals(taskStatus)) {
                normalized.add(task);
            }
        }
        return normalized;
    }

    private Map<String, Object> buildRatingDashboard(List<Map<String, Object>> tasks, LocalDateTime now) {
        Map<String, Object> dashboard = new HashMap<>();
        int totalCount = 0;
        int pendingCount = 0;
        int deferredCount = 0;
        int submittedCount = 0;
        int expiredCount = 0;
        double submittedScoreTotal = 0.0;
        int submittedScoreCount = 0;

        if (tasks != null) {
            for (Map<String, Object> task : tasks) {
                if (task == null) {
                    continue;
                }
                totalCount++;
                normalizeRatingStatus(task, now);
                String taskStatus = normalizeStatus(asString(task.get("ratingStatus")));
                if ("PENDING".equals(taskStatus)) {
                    pendingCount++;
                } else if ("DEFERRED".equals(taskStatus)) {
                    deferredCount++;
                } else if ("SUBMITTED".equals(taskStatus)) {
                    submittedCount++;
                    Double score = toDouble(task.get("ratingScore"));
                    if (score != null) {
                        submittedScoreTotal += score;
                        submittedScoreCount++;
                    }
                } else if ("EXPIRED".equals(taskStatus)) {
                    expiredCount++;
                }
            }
        }

        double avgScore = submittedScoreCount == 0 ? 0.0 : submittedScoreTotal / submittedScoreCount;
        double submitRate = totalCount == 0 ? 0.0 : (submittedCount * 100.0) / totalCount;

        dashboard.put("totalCount", totalCount);
        dashboard.put("pendingCount", pendingCount);
        dashboard.put("deferredCount", deferredCount);
        dashboard.put("submittedCount", submittedCount);
        dashboard.put("expiredCount", expiredCount);
        dashboard.put("avgScore", roundTwoDecimals(avgScore));
        dashboard.put("submitRate", roundTwoDecimals(submitRate));
        return dashboard;
    }

    private void normalizeRatingStatus(Map<String, Object> task, LocalDateTime now) {
        String taskStatus = normalizeStatus(asString(task.get("ratingStatus")));
        if (!"PENDING".equals(taskStatus) && !"DEFERRED".equals(taskStatus)) {
            return;
        }
        LocalDateTime expireAt = toLocalDateTime(task.get("expireAt"));
        if (expireAt != null && !expireAt.isAfter(now)) {
            task.put("ratingStatus", "EXPIRED");
        }
    }

    private LocalDateTime toLocalDateTime(Object value) {
        if (value instanceof LocalDateTime localDateTime) {
            return localDateTime;
        }
        if (value instanceof Timestamp timestamp) {
            return timestamp.toLocalDateTime();
        }
        if (value instanceof String text) {
            try {
                return LocalDateTime.parse(text);
            } catch (DateTimeParseException ignored) {
                try {
                    return LocalDateTime.parse(text.replace(' ', 'T'));
                } catch (DateTimeParseException ignoredAgain) {
                    return null;
                }
            }
        }
        return null;
    }

    private String normalizeStatus(String status) {
        String trimmed = safeTrim(status);
        if (trimmed == null) {
            return null;
        }
        return trimmed.toUpperCase(Locale.ROOT);
    }

    private String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private Double toDouble(Object value) {
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        if (value instanceof String text) {
            try {
                return Double.parseDouble(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private double roundTwoDecimals(double value) {
        return Math.round(value * 100.0d) / 100.0d;
    }
}
