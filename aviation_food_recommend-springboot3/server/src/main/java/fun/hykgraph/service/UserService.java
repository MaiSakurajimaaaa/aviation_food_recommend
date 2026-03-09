package fun.hykgraph.service;

import fun.hykgraph.dto.UserDTO;
import fun.hykgraph.dto.UserLoginDTO;
import fun.hykgraph.entity.User;

public interface UserService {
    User wxLogin(UserLoginDTO userLoginDTO);

    User getUser(Integer id);

    void update(UserDTO userDTO);
}
