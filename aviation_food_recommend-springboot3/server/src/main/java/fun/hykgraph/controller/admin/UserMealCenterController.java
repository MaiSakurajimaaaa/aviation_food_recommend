package fun.hykgraph.controller.admin;

import fun.hykgraph.mapper.UserMealCenterMapper;
import fun.hykgraph.result.Result;
import fun.hykgraph.vo.UserMealSelectionVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/admin/user-meal")
@Slf4j
public class UserMealCenterController {

    @Autowired
    private UserMealCenterMapper userMealCenterMapper;
    @Autowired
    private JdbcTemplate jdbcTemplate;

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
        if (!mealSelections.isEmpty() || !hasOrdersModelTables()) {
            return Result.success(mealSelections);
        }
        try {
            List<UserMealSelectionVO> orderSelections = userMealCenterMapper.listSelectionsByOrders(
                    flightNumberParam, nameParam, idNumberParam
            );
            if (!orderSelections.isEmpty()) {
                return Result.success(orderSelections);
            }
            return Result.success(mealSelections);
        } catch (Exception ex) {
            log.warn("orders模型查询失败，回退meal_selection模型。flightNumber={}, name={}, idNumber={}",
                    flightNumberParam, nameParam, idNumberParam, ex);
            return Result.success(mealSelections);
        }
    }

    private boolean hasOrdersModelTables() {
        return tableExists("orders") && tableExists("order_detail");
    }

    private boolean tableExists(String tableName) {
        try {
            Integer count = jdbcTemplate.queryForObject(
                    "select count(1) from information_schema.tables where table_schema = database() and table_name = ?",
                    Integer.class,
                    tableName
            );
            return count != null && count > 0;
        } catch (Exception ex) {
            log.warn("检查数据表存在性失败，tableName={}", tableName, ex);
            return false;
        }
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
