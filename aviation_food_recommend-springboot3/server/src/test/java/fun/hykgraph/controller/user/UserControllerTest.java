package fun.hykgraph.controller.user;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.dto.UserDTO;
import fun.hykgraph.entity.User;
import fun.hykgraph.result.Result;
import fun.hykgraph.service.UserService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserService userService;

    private UserController controller;

    @BeforeEach
    void setUp() {
        controller = new UserController();
        ReflectionTestUtils.setField(controller, "userService", userService);
    }

    @AfterEach
    void tearDown() {
        BaseContext.removeCurrentId();
    }

    @Test
    void getUser_shouldUseCurrentLoginUserIdInsteadOfPathId() {
        BaseContext.setCurrentId(100);

        User user = User.builder().id(100).name("Alice").build();
        when(userService.getUser(100)).thenReturn(user);

        Result<User> result = controller.getUser(999);

        assertNotNull(result);
        assertEquals(0, result.getCode());
        assertEquals(100, result.getData().getId());
        verify(userService).getUser(100);
    }

    @Test
    void update_shouldOverwritePayloadIdWithCurrentLoginUserId() {
        BaseContext.setCurrentId(100);

        UserDTO userDTO = new UserDTO();
        userDTO.setId(999);
        userDTO.setName("Alice");

        Result result = controller.update(userDTO);

        assertNotNull(result);
        assertEquals(0, result.getCode());

        ArgumentCaptor<UserDTO> captor = ArgumentCaptor.forClass(UserDTO.class);
        verify(userService).update(captor.capture());
        assertEquals(100, captor.getValue().getId());
    }
}
