package fun.hykgraph.controller.admin;

import fun.hykgraph.mapper.UserMealCenterMapper;
import fun.hykgraph.result.Result;
import fun.hykgraph.vo.UserMealSelectionVO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserMealCenterControllerTest {

    @Mock
    private UserMealCenterMapper userMealCenterMapper;

    @Test
    void statistics_shouldAggregateDemandByDishName() {
        UserMealCenterController controller = new UserMealCenterController();
        ReflectionTestUtils.setField(controller, "userMealCenterMapper", userMealCenterMapper);

        List<UserMealSelectionVO> rows = new ArrayList<>();

        UserMealSelectionVO first = new UserMealSelectionVO();
        first.setDishName("红烧牛腩饭、低脂鸡胸藜麦饭");
        first.setDishCount(2);
        rows.add(first);

        UserMealSelectionVO second = new UserMealSelectionVO();
        second.setDishName("第1餐：红烧牛腩饭；第2餐：香烤鳕鱼时蔬饭");
        second.setDishCount(2);
        rows.add(second);

        UserMealSelectionVO third = new UserMealSelectionVO();
        third.setDishName("-");
        third.setDishCount(0);
        rows.add(third);

        UserMealSelectionVO fourth = new UserMealSelectionVO();
        fourth.setDishName("未记录具体餐食");
        fourth.setDishCount(1);
        rows.add(fourth);

        when(userMealCenterMapper.listSelectionsByMealSelection("FUS6101", null, null)).thenReturn(rows);

        Result<Map<String, Object>> result = controller.statistics(" FUS6101 ");

        assertNotNull(result);
        assertEquals(0, result.getCode());
        assertNotNull(result.getData());
        assertEquals("FUS6101", result.getData().get("flightNumber"));
        assertEquals(4, Number.class.cast(result.getData().get("totalOrders")).intValue());
        assertEquals(3, Number.class.cast(result.getData().get("selectedOrders")).intValue());
        assertEquals(1, Number.class.cast(result.getData().get("unselectedOrders")).intValue());
        assertEquals(1, Number.class.cast(result.getData().get("unrecordedOrders")).intValue());
        assertEquals(4, Number.class.cast(result.getData().get("totalDishDemand")).intValue());
        assertEquals(3, Number.class.cast(result.getData().get("distinctDishCount")).intValue());

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> dishDemandList = (List<Map<String, Object>>) result.getData().get("dishDemandList");
        assertNotNull(dishDemandList);
        assertEquals(3, dishDemandList.size());
        assertEquals("红烧牛腩饭", dishDemandList.get(0).get("dishName"));
        assertEquals(2, Number.class.cast(dishDemandList.get(0).get("demandCount")).intValue());
        assertTrue(dishDemandList.stream().anyMatch(item -> "低脂鸡胸藜麦饭".equals(item.get("dishName"))));
        assertTrue(dishDemandList.stream().anyMatch(item -> "香烤鳕鱼时蔬饭".equals(item.get("dishName"))));

        verify(userMealCenterMapper).listSelectionsByMealSelection("FUS6101", null, null);
    }

    @Test
    void statistics_shouldRejectBlankFlightNumber() {
        UserMealCenterController controller = new UserMealCenterController();

        Result<Map<String, Object>> result = controller.statistics("   ");

        assertNotNull(result);
        assertEquals(1, result.getCode());
        assertEquals("flightNumber不能为空", result.getMsg());
    }
}
