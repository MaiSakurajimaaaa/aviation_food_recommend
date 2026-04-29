package fun.hykgraph.service.serviceImpl;

import fun.hykgraph.dto.UserDTO;
import fun.hykgraph.entity.User;
import fun.hykgraph.mapper.UserMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserMapper userMapper;

    private UserServiceImpl userService;

    @BeforeEach
    void setUp() {
        userService = new UserServiceImpl();
        ReflectionTestUtils.setField(userService, "userMapper", userMapper);
    }

    @Test
    void update_shouldFallbackInvalidCabinTypeToEconomy() {
        UserDTO dto = new UserDTO();
        dto.setId(100);
        dto.setCabinType(99);

        userService.update(dto);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userMapper).update(captor.capture());
        assertEquals(3, captor.getValue().getCabinType());
    }

    @Test
    void update_shouldKeepValidCabinType() {
        UserDTO dto = new UserDTO();
        dto.setId(100);
        dto.setCabinType(2);

        userService.update(dto);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userMapper).update(captor.capture());
        assertEquals(2, captor.getValue().getCabinType());
    }
}
