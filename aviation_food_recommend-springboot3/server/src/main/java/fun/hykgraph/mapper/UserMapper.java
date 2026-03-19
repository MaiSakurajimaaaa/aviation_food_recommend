package fun.hykgraph.mapper;

import fun.hykgraph.entity.User;
import fun.hykgraph.entity.FlightInfo;
import fun.hykgraph.vo.FlightPassengerVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Param;
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
    void bindFlight(@Param("userId") Integer userId, @Param("flightId") Integer flightId);

    @Update("update user set preference_completed = #{completed} where id = #{userId}")
    void updatePreferenceCompleted(@Param("userId") Integer userId, @Param("completed") Integer completed);

    void update(User user);

    List<FlightPassengerVO> listPassengersByFlightId(Integer flightId);

    List<FlightInfo> listFlightsByIdNumber(String idNumber);

    void insertByAdmin(User user);

    @Delete("delete from user where id = #{id}")
    void deleteById(Integer id);

    Integer countByMap(Map map);
}
