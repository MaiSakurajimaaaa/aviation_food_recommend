package fun.hykgraph.controller.admin;

import fun.hykgraph.mapper.UserMealCenterMapper;
import fun.hykgraph.result.Result;
import fun.hykgraph.vo.UserMealSelectionVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/admin/user-meal")
@Slf4j
public class UserMealCenterController {

    private static final Pattern MEAL_ORDER_PREFIX_PATTERN = Pattern.compile("^第\\d+餐[:：]");

    @Autowired
    private UserMealCenterMapper userMealCenterMapper;

    @GetMapping("/list")
    public Result<List<UserMealSelectionVO>> list(@RequestParam(required = false) String flightNumber,
                                                   @RequestParam(required = false) String name,
                                                   @RequestParam(required = false) String idNumber) {
        String flightNumberParam = trimToNull(flightNumber);
        String nameParam = trimToNull(name);
        String idNumberParam = trimToNull(idNumber);
        List<UserMealSelectionVO> mealSelections = userMealCenterMapper.listSelectionsByMealSelection(
                flightNumberParam, nameParam, idNumberParam
        );
        return Result.success(mealSelections);
    }

    @GetMapping("/statistics")
    public Result<Map<String, Object>> statistics(@RequestParam String flightNumber) {
        String flightNumberParam = trimToNull(flightNumber);
        if (flightNumberParam == null) {
            return Result.error("flightNumber不能为空");
        }

        List<UserMealSelectionVO> mealSelections = userMealCenterMapper.listSelectionsByMealSelection(
                flightNumberParam, null, null
        );

        int totalOrders = mealSelections.size();
        int selectedOrders = 0;
        int unselectedOrders = 0;
        int totalDishDemand = 0;
        int unrecordedOrders = 0;
        Map<String, Integer> demandCounter = new LinkedHashMap<>();

        for (UserMealSelectionVO selection : mealSelections) {
            boolean hasSelectedMeal = selection.getDishCount() != null && selection.getDishCount() > 0;
            if (!hasSelectedMeal) {
                unselectedOrders++;
                continue;
            }
            selectedOrders++;

            List<String> dishNames = extractDishNames(selection.getDishName());
            if (dishNames.isEmpty()) {
                unrecordedOrders++;
                continue;
            }
            totalDishDemand += dishNames.size();
            for (String dishName : dishNames) {
                demandCounter.merge(dishName, 1, Integer::sum);
            }
        }

        List<Map<String, Object>> dishDemandList = new ArrayList<>();
        demandCounter.entrySet().stream()
                .sorted(Comparator
                        .comparing((Map.Entry<String, Integer> entry) -> entry.getValue(), Comparator.reverseOrder())
                        .thenComparing(Map.Entry::getKey))
                .forEach(entry -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("dishName", entry.getKey());
                    item.put("demandCount", entry.getValue());
                    dishDemandList.add(item);
                });

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("flightNumber", flightNumberParam);
        summary.put("totalOrders", totalOrders);
        summary.put("selectedOrders", selectedOrders);
        summary.put("unselectedOrders", unselectedOrders);
        summary.put("unrecordedOrders", unrecordedOrders);
        summary.put("totalDishDemand", totalDishDemand);
        summary.put("distinctDishCount", demandCounter.size());
        summary.put("dishDemandList", dishDemandList);
        return Result.success(summary);
    }

    private List<String> extractDishNames(String rawDishNames) {
        String normalized = trimToNull(rawDishNames);
        if (normalized == null
                || "-".equals(normalized)
                || normalized.contains("未记录具体餐食")) {
            return List.of();
        }

        String sanitized = normalized
                .replace("[", "")
                .replace("]", "")
                .replace("\"", "")
                .trim();
        if (sanitized.isEmpty()) {
            return List.of();
        }

        String[] tokens = sanitized.split("[、,，;；]");
        List<String> dishNames = new ArrayList<>();
        for (String token : tokens) {
            String value = trimToNull(token);
            if (value == null) {
                continue;
            }
            value = MEAL_ORDER_PREFIX_PATTERN.matcher(value).replaceFirst("").trim();
            if (value.isEmpty() || "-".equals(value) || value.contains("未记录具体餐食")) {
                continue;
            }
            if (value.matches("\\d+")) {
                value = "餐食ID-" + value;
            }
            dishNames.add(value);
        }
        return dishNames;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
