package fun.hykgraph.controller.admin;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.entity.FlightAnnouncement;
import fun.hykgraph.mapper.FlightAnnouncementMapper;
import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.result.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
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
        Map<String, Object> dashboard = recommendationMapper.ratingDashboard();
        return Result.success(dashboard == null ? Collections.emptyMap() : dashboard);
    }

    @GetMapping("/recommendation/rating/list")
    public Result<List<Map<String, Object>>> ratingList(@RequestParam(required = false) String status,
                                                         @RequestParam(required = false) String flightNumber,
                                                         @RequestParam(required = false) String userKeyword) {
        return Result.success(recommendationMapper.ratingTaskList(status, safeTrim(flightNumber), safeTrim(userKeyword)));
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
}
