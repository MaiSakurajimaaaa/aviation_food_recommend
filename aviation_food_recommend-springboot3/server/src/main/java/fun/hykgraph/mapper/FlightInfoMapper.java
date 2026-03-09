package fun.hykgraph.mapper;

import fun.hykgraph.entity.FlightInfo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface FlightInfoMapper {

    List<FlightInfo> listAll();

    void insert(FlightInfo flightInfo);

    void update(FlightInfo flightInfo);

    void deleteById(Integer id);

    @Select("select * from flight_info where id = #{id}")
    FlightInfo getById(Integer id);

    @Select("select * from flight_info where flight_number = #{flightNumber} limit 1")
    FlightInfo getByFlightNumber(String flightNumber);
}
