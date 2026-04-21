package fun.hykgraph.controller.admin;

import fun.hykgraph.dto.FlightPassengerDTO;
import fun.hykgraph.mapper.UserMapper;
import fun.hykgraph.mapper.UserPreferenceMapper;
import fun.hykgraph.result.Result;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verifyNoInteractions;

@ExtendWith(MockitoExtension.class)
class FlightControllerTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private UserPreferenceMapper userPreferenceMapper;

    private FlightController controller;

    @BeforeEach
    void setUp() {
        controller = new FlightController();
        ReflectionTestUtils.setField(controller, "userMapper", userMapper);
        ReflectionTestUtils.setField(controller, "userPreferenceMapper", userPreferenceMapper);
    }

    @Test
    void addPassenger_shouldRejectInvalidIdNumberBirthDate() {
        FlightPassengerDTO dto = new FlightPassengerDTO();
        dto.setFlightId(1);
        dto.setName("测试客户");
        dto.setCabinType(3);
        dto.setIdNumber("420101199000000124");

        Result result = controller.addPassenger(dto);

        assertNotNull(result);
        assertEquals(1, result.getCode());
        assertEquals("身份证号格式不正确", result.getMsg());
        verifyNoInteractions(userMapper);
    }

    @Test
    void updatePassenger_shouldRejectInvalidIdNumberBirthDate() {
        FlightPassengerDTO dto = new FlightPassengerDTO();
        dto.setId(100);
        dto.setFlightId(1);
        dto.setName("测试客户");
        dto.setCabinType(3);
        dto.setIdNumber("420101199000000124");

        Result result = controller.updatePassenger(dto);

        assertNotNull(result);
        assertEquals(1, result.getCode());
        assertEquals("身份证号格式不正确", result.getMsg());
        verifyNoInteractions(userMapper);
    }
}
