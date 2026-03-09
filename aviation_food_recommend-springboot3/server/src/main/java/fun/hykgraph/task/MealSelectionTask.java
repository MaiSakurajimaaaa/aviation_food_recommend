package fun.hykgraph.task;

import fun.hykgraph.entity.FlightAnnouncement;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.entity.UserPreference;
import fun.hykgraph.mapper.DishMapper;
import fun.hykgraph.mapper.FlightAnnouncementMapper;
import fun.hykgraph.mapper.FlightInfoMapper;
import fun.hykgraph.mapper.RecommendationMapper;
import fun.hykgraph.mapper.UserPreferenceMapper;
import fun.hykgraph.vo.RecommendationDishVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@Slf4j
public class MealSelectionTask {

    @Autowired
    private FlightInfoMapper flightInfoMapper;
    @Autowired
    private RecommendationMapper recommendationMapper;
    @Autowired
    private UserPreferenceMapper userPreferenceMapper;
    @Autowired
    private DishMapper dishMapper;
    @Autowired
    private FlightAnnouncementMapper announcementMapper;

    @Scheduled(cron = "0 */5 * * * ?")
    public void autoSelectWhenOverdue() {
        LocalDateTime now = LocalDateTime.now();
        List<FlightInfo> flights = flightInfoMapper.listAll();
        for (FlightInfo flight : flights) {
            if (flight == null || flight.getId() == null || flight.getStatus() == null || flight.getStatus() != 1) {
                continue;
            }
            if (flight.getSelectionDeadline() == null || flight.getSelectionDeadline().isAfter(now)) {
                continue;
            }
            if (flight.getDepartureTime() != null && flight.getDepartureTime().isBefore(now)) {
                continue;
            }
            List<Map<String, Object>> users = recommendationMapper.listUsersWithoutSelectionByFlightId(flight.getId());
            for (Map<String, Object> userRow : users) {
                Integer userId = toInteger(userRow.get("userId"));
                if (userId == null) {
                    continue;
                }
                Integer existCount = recommendationMapper.existsMealSelection(userId, flight.getId());
                if (existCount != null && existCount > 0) {
                    continue;
                }
                autoPickForUser(userId, flight);
            }
        }
    }

    @Scheduled(cron = "0 */10 * * * ?")
    public void pushSelectionReminder() {
        LocalDateTime now = LocalDateTime.now();
        List<FlightInfo> flights = flightInfoMapper.listAll();
        for (FlightInfo flight : flights) {
            if (flight == null || flight.getId() == null || flight.getDepartureTime() == null || flight.getStatus() == null || flight.getStatus() != 1) {
                continue;
            }
            long hours = ChronoUnit.HOURS.between(now, flight.getDepartureTime());
            if (hours == 12) {
                sendReminder(flight, "T-12");
            }
            if (hours == 3) {
                sendReminder(flight, "T-3");
            }
        }
    }

    private void sendReminder(FlightInfo flight, String remindType) {
        String flightDate = flight.getDepartureTime().toLocalDate().toString();
        Integer exists = recommendationMapper.countReminderLog(flight.getId(), remindType, flightDate);
        if (exists != null && exists > 0) {
            return;
        }
        FlightAnnouncement announcement = new FlightAnnouncement();
        announcement.setFlightId(flight.getId());
        announcement.setTitle(flight.getFlightNumber() + " 选餐提醒 " + remindType);
        announcement.setContent("航班 " + flight.getFlightNumber() + " 将于 " + remindType + " 起飞，请尽快完成餐食预选。");
        announcement.setStatus(1);
        announcement.setCreateUser(0);
        announcement.setCreateTime(LocalDateTime.now());
        announcement.setUpdateTime(LocalDateTime.now());
        announcementMapper.insert(announcement);
        recommendationMapper.insertReminderLog(flight.getId(), remindType, flightDate, LocalDateTime.now());
    }

    private void autoPickForUser(Integer userId, FlightInfo flight) {
        UserPreference preference = userPreferenceMapper.getByUserId(userId);
        Integer mealType = parseMealType(preference == null ? null : preference.getMealTypePreferences());
        String flavor = parseFlavor(preference == null ? null : preference.getFlavorPreferences());

        List<RecommendationDishVO> candidates = recommendationMapper.listCandidateDishes(flight.getId(), mealType, flavor, 20);
        if (candidates == null || candidates.isEmpty()) {
            log.warn("逾期自动选餐失败：无候选餐食，userId={}, flightId={}", userId, flight.getId());
            return;
        }

        RecommendationDishVO selected = null;
        Integer fallbackLevel = 0;
        for (RecommendationDishVO candidate : candidates) {
            if (candidate == null || candidate.getDishId() == null) {
                continue;
            }
            Integer affected = dishMapper.decreaseStockAndAutoDisable(candidate.getDishId(), 1);
            if (affected != null && affected > 0) {
                selected = candidate;
                break;
            }
            dishMapper.disableIfOutOfStock(candidate.getDishId());
            fallbackLevel++;
        }

        if (selected == null) {
            log.warn("逾期自动选餐失败：库存不足无法降级，userId={}, flightId={}", userId, flight.getId());
            return;
        }

        Map<String, Object> selection = new HashMap<>();
        selection.put("number", "AUTO" + System.currentTimeMillis() + userId);
        selection.put("status", 5);
        selection.put("userId", userId);
        selection.put("flightId", flight.getId());
        selection.put("seatNumber", "AUTO");
        selection.put("createTime", LocalDateTime.now());
        selection.put("updateTime", LocalDateTime.now());
        recommendationMapper.insertMealSelection(selection);

        Map<String, Object> recommendLog = new HashMap<>();
        recommendLog.put("userId", userId);
        recommendLog.put("flightId", flight.getId());
        recommendLog.put("recommendedDishes", "[" + selected.getDishId() + "]");
        recommendLog.put("algorithmType", "fused-pmfup-prmidm-ammbc-v1");
        recommendLog.put("userFeedback", "AUTO_SELECTED_OVERDUE:dishId=" + selected.getDishId());
        recommendationMapper.insertLog(recommendLog);

        log.info("逾期自动选餐完成，userId={}, flightId={}, dishId={}, fallbackLevel={}",
                userId, flight.getId(), selected.getDishId(), fallbackLevel);
    }

    private Integer parseMealType(String raw) {
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

    private String parseFlavor(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return null;
        }
        String compact = raw.replace("[", "").replace("]", "").replace("\"", "").trim();
        if (compact.isEmpty()) {
            return null;
        }
        String first = compact.split(",")[0].trim();
        return first.isEmpty() ? null : first;
    }

    private Integer toInteger(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Long) {
            return ((Long) value).intValue();
        }
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }
}
