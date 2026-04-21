package fun.hykgraph.mapper;

import fun.hykgraph.vo.FlightMealBindingVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface FlightRouteDishMapper {

    List<FlightMealBindingVO> listByFlightNumber(@Param("flightNumber") String flightNumber);

    Integer countByFlightNumberAndDishId(@Param("flightNumber") String flightNumber,
                                         @Param("dishId") Integer dishId,
                                         @Param("cabinType") Integer cabinType,
                                         @Param("excludeId") Integer excludeId);

    void insertBinding(@Param("departure") String departure,
                       @Param("destination") String destination,
                       @Param("dishId") Integer dishId,
                       @Param("dishSource") Integer dishSource,
                       @Param("cabinType") Integer cabinType,
                       @Param("sort") Integer sort);

    void updateBinding(@Param("id") Integer id,
                       @Param("departure") String departure,
                       @Param("destination") String destination,
                       @Param("dishId") Integer dishId,
                       @Param("dishSource") Integer dishSource,
                       @Param("cabinType") Integer cabinType,
                       @Param("sort") Integer sort);

    void deleteById(@Param("id") Integer id);
}
