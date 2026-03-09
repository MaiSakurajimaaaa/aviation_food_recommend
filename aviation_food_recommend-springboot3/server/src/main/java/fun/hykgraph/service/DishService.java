package fun.hykgraph.service;

import fun.hykgraph.dto.DishDTO;
import fun.hykgraph.dto.DishPageDTO;
import fun.hykgraph.entity.Dish;
import fun.hykgraph.result.PageResult;
import fun.hykgraph.vo.DishVO;

import java.util.List;

public interface DishService {
    void addDishWithFlavor(DishDTO dishDTO);

    PageResult getPageList(DishPageDTO dishPageDTO);

    DishVO getDishWithFlavorById(Integer id);

    void updateDishWithFlavor(DishDTO dishDTO);

    void deleteBatch(List<Integer> ids);

    void onOff(Integer id);

    List<DishVO> getDishesWithFlavorById(Dish dish);
}
