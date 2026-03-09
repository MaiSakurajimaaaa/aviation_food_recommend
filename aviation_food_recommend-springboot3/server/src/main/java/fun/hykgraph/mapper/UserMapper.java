package fun.hykgraph.mapper;

import fun.hykgraph.entity.User;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.vo.FlightPassengerVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.Map;
import java.util.List;

@Mapper
public interface UserMapper {

    @Select("select * from user where openid = #{openid}")
    User getByOpenid(String openid);

    void insert(User user);

    @Select("select * from user where id = #{id}")
    User getById(Integer id);

    @Update("update user set current_flight_id = #{flightId} where id = #{userId}")
    void bindFlight(Integer userId, Integer flightId);

    @Update("update user set preference_completed = 1 where id = #{userId}")
    void completePreference(Integer userId);

    void update(User user);

    List<FlightPassengerVO> listPassengersByFlightId(Integer flightId);

    List<FlightInfo> listFlightsByIdNumber(String idNumber);

    void insertByAdmin(User user);

    @Delete("delete from user where id = #{id}")
    void deleteById(Integer id);

    Integer countByMap(Map map);
}
