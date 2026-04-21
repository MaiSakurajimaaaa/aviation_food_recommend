package fun.hykgraph.controller.user;

import fun.hykgraph.constant.JwtClaimsConstant;
import fun.hykgraph.context.BaseContext;
import fun.hykgraph.dto.UserDTO;
import fun.hykgraph.dto.UserLoginDTO;
import fun.hykgraph.entity.User;
import fun.hykgraph.exception.BaseException;
import fun.hykgraph.properties.JwtProperties;
import fun.hykgraph.result.Result;
import fun.hykgraph.service.UserService;
import fun.hykgraph.utils.JwtUtil;
import fun.hykgraph.vo.UserLoginVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/user/user")
@Slf4j
public class UserController {

    @Autowired
    private UserService userService;
    @Autowired
    private JwtProperties jwtProperties;

    @PostMapping("/login")
    public Result<UserLoginVO> login(@RequestBody UserLoginDTO userLoginDTO){
        log.info("用户传过来的登录信息：{}", userLoginDTO);
        User user = userService.wxLogin(userLoginDTO);

        // 上面的没抛异常，正常来到这里，说明登录成功
        // claims就是用户数据payload部分
        Map<String, Object> claims = new HashMap<>(); // jsonwebtoken包底层就是Map<String, Object>格式，不能修改！
        claims.put(JwtClaimsConstant.USER_ID, user.getId());
        // 需要加个token给他，再返回响应
        String token = JwtUtil.createJWT(
                jwtProperties.getUserSecretKey(),
                jwtProperties.getUserTtl(),
                claims);
        UserLoginVO userLoginVO = UserLoginVO.builder()
                .id(user.getId())
                .openid(user.getOpenid())
                .token(token)
                .build();
        return Result.success(userLoginVO);
    }

    /**
     * 根据id查询用户
     * @return
     */
    @GetMapping("/{id}")
    public Result<User> getUser(@PathVariable Integer id){
        Integer currentUserId = getCurrentUserId();
        if (id != null && !currentUserId.equals(id)) {
            log.warn("用户资料查询id不一致，pathId:{}, currentUserId:{}", id, currentUserId);
        }
        User user = userService.getUser(currentUserId);
        return Result.success(user);
    }

    /**
     * 修改用户信息
     * @param userDTO
     * @return
     */
    @PutMapping
    public Result<Void> update(@RequestBody UserDTO userDTO){
        Integer currentUserId = getCurrentUserId();
        userDTO.setId(currentUserId);
        log.info("更新用户信息，currentUserId:{}", currentUserId);
        userService.update(userDTO);
        return Result.success();
    }

    private Integer getCurrentUserId() {
        Integer currentUserId = BaseContext.getCurrentId();
        if (currentUserId == null) {
            throw new BaseException("登录信息失效，请重新登录");
        }
        return currentUserId;
    }

}
