package fun.hykgraph.mapper;

import fun.hykgraph.entity.DishFlavor;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface DishFlavorMapper {

    void insertBatch(List<DishFlavor> flavorList);

    List<DishFlavor> getByDishId(Integer dishId);

    void deleteByDishId(Integer dishId);

    void deleteBatch(List<Integer> ids);
}
