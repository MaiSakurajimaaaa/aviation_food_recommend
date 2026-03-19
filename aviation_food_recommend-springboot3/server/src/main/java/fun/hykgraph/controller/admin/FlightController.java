package fun.hykgraph.controller.admin;

import fun.hykgraph.context.BaseContext;
import fun.hykgraph.dto.FlightMealBindingDTO;
import fun.hykgraph.dto.FlightPassengerDTO;
import fun.hykgraph.entity.Dish;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.entity.User;
import fun.hykgraph.entity.UserPreference;
import fun.hykgraph.mapper.DishMapper;
import fun.hykgraph.mapper.FlightInfoMapper;
import fun.hykgraph.mapper.FlightRouteDishMapper;
import fun.hykgraph.mapper.UserMapper;
import fun.hykgraph.mapper.UserPreferenceMapper;
import fun.hykgraph.result.Result;
import fun.hykgraph.vo.FlightMealBindingVO;
import fun.hykgraph.vo.FlightPassengerVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/admin/flight")
@Slf4j
public class FlightController {

    @Autowired
    private FlightInfoMapper flightInfoMapper;
    @Autowired
    private FlightRouteDishMapper flightRouteDishMapper;
    @Autowired
    private DishMapper dishMapper;
    @Autowired
    private UserMapper userMapper;
    @Autowired
    private UserPreferenceMapper userPreferenceMapper;

    @GetMapping("/list")
    public Result<List<FlightInfo>> list() {
        return Result.success(flightInfoMapper.listAll());
    }

    @PostMapping
    public Result add(@RequestBody FlightInfo flightInfo) {
        String validation = validateFlightInfo(flightInfo, false);
        if (validation != null) {
            return Result.error(validation);
        }
        FlightInfo duplicated = flightInfoMapper.getByFlightNumber(flightInfo.getFlightNumber());
        if (duplicated != null) {
            return Result.error("航班号已存在");
        }
        Integer adminId = BaseContext.getCurrentId();
        LocalDateTime now = LocalDateTime.now();
        if (flightInfo.getDepartureTime() != null && flightInfo.getArrivalTime() != null) {
            long minutes = java.time.Duration.between(flightInfo.getDepartureTime(), flightInfo.getArrivalTime()).toMinutes();
            flightInfo.setDurationMinutes((int) Math.max(0, minutes));
        }
        if (flightInfo.getMealCount() == null) {
            flightInfo.setMealCount(flightInfo.getDurationMinutes() != null && flightInfo.getDurationMinutes() >= 180 ? 2 : 1);
        }
        flightInfo.setStatus(flightInfo.getStatus() == null ? 1 : flightInfo.getStatus());
        flightInfo.setCreateUser(adminId);
        flightInfo.setUpdateUser(adminId);
        flightInfo.setCreateTime(now);
        flightInfo.setUpdateTime(now);
        flightInfoMapper.insert(flightInfo);
        return Result.success();
    }

    @PutMapping
    public Result update(@RequestBody FlightInfo flightInfo) {
        String validation = validateFlightInfo(flightInfo, true);
        if (validation != null) {
            return Result.error(validation);
        }
        FlightInfo existed = flightInfoMapper.getByFlightNumber(flightInfo.getFlightNumber());
        if (existed != null && !existed.getId().equals(flightInfo.getId())) {
            return Result.error("航班号已存在");
        }
        Integer adminId = BaseContext.getCurrentId();
        if (flightInfo.getDepartureTime() != null && flightInfo.getArrivalTime() != null) {
            long minutes = java.time.Duration.between(flightInfo.getDepartureTime(), flightInfo.getArrivalTime()).toMinutes();
            flightInfo.setDurationMinutes((int) Math.max(0, minutes));
        }
        if (flightInfo.getMealCount() == null && flightInfo.getDurationMinutes() != null) {
            flightInfo.setMealCount(flightInfo.getDurationMinutes() >= 180 ? 2 : 1);
        }
        flightInfo.setUpdateUser(adminId);
        flightInfo.setUpdateTime(LocalDateTime.now());
        flightInfoMapper.update(flightInfo);
        return Result.success();
    }

    @DeleteMapping("/{id}")
    public Result delete(@PathVariable Integer id) {
        flightInfoMapper.deleteById(id);
        return Result.success();
    }

    private String validateFlightInfo(FlightInfo flightInfo, boolean requireId) {
        if (flightInfo == null) {
            return "航班数据不能为空";
        }
        if (requireId && flightInfo.getId() == null) {
            return "航班ID不能为空";
        }
        if (flightInfo.getFlightNumber() == null || flightInfo.getFlightNumber().trim().isEmpty()) {
            return "航班号不能为空";
        }
        flightInfo.setFlightNumber(flightInfo.getFlightNumber().trim().toUpperCase());
        if (flightInfo.getDeparture() == null || flightInfo.getDeparture().trim().isEmpty()) {
            return "出发地不能为空";
        }
        if (flightInfo.getDestination() == null || flightInfo.getDestination().trim().isEmpty()) {
            return "目的地不能为空";
        }
        flightInfo.setDeparture(flightInfo.getDeparture().trim());
        flightInfo.setDestination(flightInfo.getDestination().trim());

        LocalDateTime departureTime = flightInfo.getDepartureTime();
        LocalDateTime arrivalTime = flightInfo.getArrivalTime();
        if (departureTime != null && arrivalTime != null && !arrivalTime.isAfter(departureTime)) {
            return "到达时间必须晚于起飞时间";
        }
        if (flightInfo.getSelectionDeadline() != null && departureTime != null
                && flightInfo.getSelectionDeadline().isAfter(departureTime)) {
            return "预选截止时间不能晚于起飞时间";
        }
        if (flightInfo.getDurationMinutes() != null && flightInfo.getDurationMinutes() < 30) {
            return "飞行时长不能少于30分钟";
        }
        return null;
    }

    @GetMapping("/passengers/{flightId}")
    public Result<List<FlightPassengerVO>> passengers(@PathVariable Integer flightId) {
        return Result.success(userMapper.listPassengersByFlightId(flightId));
    }

    @PostMapping("/passenger")
    public Result addPassenger(@RequestBody FlightPassengerDTO dto) {
        if (dto.getFlightId() == null) {
            return Result.error("flightId 不能为空");
        }
        User user = User.builder()
                .name(dto.getName())
                .openid("admin-manual-" + UUID.randomUUID())
                .phone(dto.getPhone())
                .gender(dto.getGender())
                .idNumber(dto.getIdNumber())
                .preferenceCompleted(0)
                .currentFlightId(dto.getFlightId())
                .createTime(LocalDateTime.now())
                .build();
        userMapper.insertByAdmin(user);
        return Result.success();
    }

    @PutMapping("/passenger")
    public Result updatePassenger(@RequestBody FlightPassengerDTO dto) {
        if (dto.getId() == null) {
            return Result.error("id 不能为空");
        }
        User user = User.builder()
                .id(dto.getId())
                .name(dto.getName())
                .phone(dto.getPhone())
                .gender(dto.getGender())
                .idNumber(dto.getIdNumber())
                .preferenceCompleted(resolvePreferenceCompleted(dto.getId()))
                .currentFlightId(dto.getFlightId())
                .build();
        userMapper.update(user);
        return Result.success();
    }

    private Integer resolvePreferenceCompleted(Integer userId) {
        if (userId == null) {
            return 0;
        }
        UserPreference preference = userPreferenceMapper.getByUserId(userId);
        if (preference == null) {
            return 0;
        }
        String raw = preference.getFlavorPreferences();
        if (raw == null || raw.trim().isEmpty()) {
            return 0;
        }
        String compact = raw.replace("[", "").replace("]", "").replace("\"", "").trim();
        return compact.isEmpty() ? 0 : 1;
    }

    @DeleteMapping("/passenger/{id}")
    public Result deletePassenger(@PathVariable Integer id) {
        userMapper.deleteById(id);
        return Result.success();
    }

    @GetMapping("/meals/{flightNumber}")
    public Result<List<FlightMealBindingVO>> listMeals(@PathVariable String flightNumber) {
        if (flightNumber == null || flightNumber.trim().isEmpty()) {
            return Result.error("航班号不能为空");
        }
        return Result.success(flightRouteDishMapper.listByFlightNumber(flightNumber.trim()));
    }

    @PostMapping("/meal")
    public Result addMeal(@RequestBody FlightMealBindingDTO dto) {
        if (dto.getFlightNumber() == null || dto.getFlightNumber().trim().isEmpty()) {
            return Result.error("航班号不能为空");
        }
        if (dto.getDishId() == null) {
            return Result.error("dishId 不能为空");
        }
        FlightInfo flightInfo = flightInfoMapper.getByFlightNumber(dto.getFlightNumber().trim());
        if (flightInfo == null) {
            return Result.error("航班不存在");
        }
        Dish dish = dishMapper.getById(dto.getDishId());
        if (dish == null) {
            return Result.error("餐食不存在");
        }
        Integer duplicated = flightRouteDishMapper.countByFlightNumberAndDishId(dto.getFlightNumber().trim(), dto.getDishId(), null);
        if (duplicated != null && duplicated > 0) {
            return Result.error("该航班已绑定该餐食");
        }
        flightRouteDishMapper.insertBinding(
                flightInfo.getDeparture(),
                flightInfo.getDestination(),
                dto.getDishId(),
                dto.getDishSource() == null ? 1 : dto.getDishSource(),
                dto.getSort() == null ? 1 : dto.getSort()
        );
        return Result.success();
    }

    @PutMapping("/meal")
    public Result updateMeal(@RequestBody FlightMealBindingDTO dto) {
        if (dto.getId() == null) {
            return Result.error("id 不能为空");
        }
        if (dto.getFlightNumber() == null || dto.getFlightNumber().trim().isEmpty()) {
            return Result.error("航班号不能为空");
        }
        if (dto.getDishId() == null) {
            return Result.error("dishId 不能为空");
        }
        FlightInfo flightInfo = flightInfoMapper.getByFlightNumber(dto.getFlightNumber().trim());
        if (flightInfo == null) {
            return Result.error("航班不存在");
        }
        Dish dish = dishMapper.getById(dto.getDishId());
        if (dish == null) {
            return Result.error("餐食不存在");
        }
        Integer duplicated = flightRouteDishMapper.countByFlightNumberAndDishId(dto.getFlightNumber().trim(), dto.getDishId(), dto.getId());
        if (duplicated != null && duplicated > 0) {
            return Result.error("该航班已绑定该餐食");
        }
        flightRouteDishMapper.updateBinding(
                dto.getId(),
                flightInfo.getDeparture(),
                flightInfo.getDestination(),
                dto.getDishId(),
                dto.getDishSource() == null ? 1 : dto.getDishSource(),
                dto.getSort() == null ? 1 : dto.getSort()
        );
        return Result.success();
    }

    @DeleteMapping("/meal/{id}")
    public Result deleteMeal(@PathVariable Integer id) {
        flightRouteDishMapper.deleteById(id);
        return Result.success();
    }
}
