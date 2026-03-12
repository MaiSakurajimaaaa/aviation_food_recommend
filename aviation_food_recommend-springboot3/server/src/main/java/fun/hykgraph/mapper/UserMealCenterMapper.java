package fun.hykgraph.mapper;

import fun.hykgraph.vo.UserMealSelectionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface UserMealCenterMapper {

    List<UserMealSelectionVO> listSelectionsByMealSelection(@Param("flightNumber") String flightNumber,
                                                            @Param("name") String name,
                                                            @Param("idNumber") String idNumber);
}
