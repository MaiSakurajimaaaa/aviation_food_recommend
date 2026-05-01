package fun.hykgraph.mapper;

import com.github.pagehelper.Page;
import fun.hykgraph.annotation.AutoFill;
import fun.hykgraph.dto.DishDTO;
import fun.hykgraph.dto.DishPageDTO;
import fun.hykgraph.entity.Dish;
import fun.hykgraph.enumeration.OperationType;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.List;

@Mapper
public interface DishMapper {
    @AutoFill(OperationType.INSERT)
    void addDish(Dish dish);

    Page<Dish> getPageList(DishPageDTO dishPageDTO);

    @Select("select * from dish where id = #{id}")
    Dish getById(Integer id);

    @AutoFill(OperationType.UPDATE)
    void update(Dish dish);

    void deleteBatch(List<Integer> ids);

    @Update("update dish set status = IF(status = 0, 1, 0) where id = #{id}")
    void onOff(Integer id);

    List<Dish> getList(Dish dish);

    @Update("update dish set stock = stock - #{count}, status = if(stock - #{count} <= 0, 0, status) where id = #{dishId} and status = 1 and stock >= #{count}")
    Integer decreaseStockAndAutoDisable(@Param("dishId") Integer dishId, @Param("count") Integer count);

    @Update("update dish set status = 0 where id = #{dishId} and ifnull(stock, 0) <= 0")
    Integer disableIfOutOfStock(@Param("dishId") Integer dishId);

    @Update("update dish set stock = ifnull(stock, 0) + #{count}, status = 1 where id = #{dishId}")
    Integer increaseStockAndEnable(@Param("dishId") Integer dishId, @Param("count") Integer count);
}
