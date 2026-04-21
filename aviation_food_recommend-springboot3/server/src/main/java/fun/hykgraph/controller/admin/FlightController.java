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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/admin/flight")
@Slf4j
public class FlightController {

    private static final int CABIN_FIRST = 1;
    private static final int CABIN_BUSINESS = 2;
    private static final int CABIN_ECONOMY = 3;
    private static final Pattern ID_NUMBER_PATTERN = Pattern.compile("^\\d{17}[\\dXx]$");
    private static final DateTimeFormatter ID_BIRTHDAY_FORMATTER = DateTimeFormatter.ofPattern("uuuuMMdd").withResolverStyle(ResolverStyle.STRICT);

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
        if (!isValidUserCabinType(dto.getCabinType())) {
            return Result.error("旅客舱型不合法，仅支持1-头等舱、2-商务舱、3-经济舱");
        }
        if (!isValidIdNumber(dto.getIdNumber())) {
            return Result.error("身份证号格式不正确");
        }
        String normalizedIdNumber = normalizeIdNumber(dto.getIdNumber());
        User user = User.builder()
                .name(dto.getName())
                .openid("admin-manual-" + UUID.randomUUID())
                .phone(dto.getPhone())
                .gender(dto.getGender())
                .idNumber(normalizedIdNumber)
                .preferenceCompleted(0)
                .currentFlightId(dto.getFlightId())
                .cabinType(resolveUserCabinType(dto.getCabinType()))
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
        if (!isValidUserCabinType(dto.getCabinType())) {
            return Result.error("旅客舱型不合法，仅支持1-头等舱、2-商务舱、3-经济舱");
        }
        if (!isValidIdNumber(dto.getIdNumber())) {
            return Result.error("身份证号格式不正确");
        }
        String normalizedIdNumber = normalizeIdNumber(dto.getIdNumber());
        User user = User.builder()
                .id(dto.getId())
                .name(dto.getName())
                .phone(dto.getPhone())
                .gender(dto.getGender())
                .idNumber(normalizedIdNumber)
                .preferenceCompleted(resolvePreferenceCompleted(dto.getId()))
                .currentFlightId(dto.getFlightId())
                .cabinType(resolveUserCabinType(dto.getCabinType()))
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

    private boolean isValidIdNumber(String idNumber) {
        String normalized = normalizeIdNumber(idNumber);
        if (normalized == null) {
            return true;
        }
        if (!ID_NUMBER_PATTERN.matcher(normalized).matches()) {
            return false;
        }
        String birthday = normalized.substring(6, 14);
        LocalDate birthdayDate;
        try {
            birthdayDate = LocalDate.parse(birthday, ID_BIRTHDAY_FORMATTER);
        } catch (DateTimeParseException ex) {
            return false;
        }
        LocalDate today = LocalDate.now();
        return !birthdayDate.isAfter(today) && !birthdayDate.isBefore(today.minusYears(130));
    }

    private String normalizeIdNumber(String idNumber) {
        if (idNumber == null) {
            return null;
        }
        String normalized = idNumber.trim();
        if (normalized.isEmpty()) {
            return null;
        }
        return normalized.toUpperCase();
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
        if (!isValidMealCabinType(dto.getCabinType())) {
            return Result.error("餐食舱型不合法，仅支持1-头等舱、2-商务舱、3-经济舱");
        }
        FlightInfo flightInfo = flightInfoMapper.getByFlightNumber(dto.getFlightNumber().trim());
        if (flightInfo == null) {
            return Result.error("航班不存在");
        }
        Dish dish = dishMapper.getById(dto.getDishId());
        if (dish == null) {
            return Result.error("餐食不存在");
        }
        Integer cabinType = resolveMealCabinType(dto.getCabinType());
        Integer duplicated = flightRouteDishMapper.countByFlightNumberAndDishId(dto.getFlightNumber().trim(), dto.getDishId(), cabinType, null);
        if (duplicated != null && duplicated > 0) {
            return Result.error("该航班在当前舱型下已绑定该餐食");
        }
        flightRouteDishMapper.insertBinding(
                flightInfo.getDeparture(),
                flightInfo.getDestination(),
                dto.getDishId(),
                dto.getDishSource() == null ? 1 : dto.getDishSource(),
                cabinType,
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
        if (!isValidMealCabinType(dto.getCabinType())) {
            return Result.error("餐食舱型不合法，仅支持1-头等舱、2-商务舱、3-经济舱");
        }
        FlightInfo flightInfo = flightInfoMapper.getByFlightNumber(dto.getFlightNumber().trim());
        if (flightInfo == null) {
            return Result.error("航班不存在");
        }
        Dish dish = dishMapper.getById(dto.getDishId());
        if (dish == null) {
            return Result.error("餐食不存在");
        }
        Integer cabinType = resolveMealCabinType(dto.getCabinType());
        Integer duplicated = flightRouteDishMapper.countByFlightNumberAndDishId(dto.getFlightNumber().trim(), dto.getDishId(), cabinType, dto.getId());
        if (duplicated != null && duplicated > 0) {
            return Result.error("该航班在当前舱型下已绑定该餐食");
        }
        flightRouteDishMapper.updateBinding(
                dto.getId(),
                flightInfo.getDeparture(),
                flightInfo.getDestination(),
                dto.getDishId(),
                dto.getDishSource() == null ? 1 : dto.getDishSource(),
                cabinType,
                dto.getSort() == null ? 1 : dto.getSort()
        );
        return Result.success();
    }

    @DeleteMapping("/meal/{id}")
    public Result deleteMeal(@PathVariable Integer id) {
        flightRouteDishMapper.deleteById(id);
        return Result.success();
    }

    private boolean isValidUserCabinType(Integer cabinType) {
        return cabinType == null || cabinType == CABIN_FIRST || cabinType == CABIN_BUSINESS || cabinType == CABIN_ECONOMY;
    }

    private Integer resolveUserCabinType(Integer cabinType) {
        if (cabinType == null) {
            return CABIN_ECONOMY;
        }
        return isValidUserCabinType(cabinType) ? cabinType : CABIN_ECONOMY;
    }

    private boolean isValidMealCabinType(Integer cabinType) {
        return cabinType == null
                || cabinType == CABIN_FIRST
                || cabinType == CABIN_BUSINESS
                || cabinType == CABIN_ECONOMY;
    }

    private Integer resolveMealCabinType(Integer cabinType) {
        if (cabinType == null) {
            return CABIN_ECONOMY;
        }
        return isValidMealCabinType(cabinType) ? cabinType : CABIN_ECONOMY;
    }
}
