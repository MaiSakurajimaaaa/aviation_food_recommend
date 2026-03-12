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

import java.util.List;

@RestController
@RequestMapping("/admin/user-meal")
@Slf4j
public class UserMealCenterController {

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

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
