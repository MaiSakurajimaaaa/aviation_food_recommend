package fun.hykgraph.service;

import fun.hykgraph.dto.SetmealDTO;
import fun.hykgraph.dto.SetmealPageDTO;
import fun.hykgraph.entity.Setmeal;
import fun.hykgraph.result.PageResult;
import fun.hykgraph.vo.DishItemVO;
import fun.hykgraph.vo.SetmealVO;
import fun.hykgraph.vo.SetmealWithPicVO;

import java.util.List;

public interface SetmealService {
    void addSetmeal(SetmealDTO setmealDTO);

    PageResult getPageList(SetmealPageDTO setmealPageDTO);

    SetmealVO getSetmealById(Integer id);

    void onOff(Integer id);

    void update(SetmealDTO setmealDTO);

    void deleteBatch(List<Integer> ids);

    List<Setmeal> getList(Integer categoryId);

    List<DishItemVO> getSetmealDishesById(Integer id);

    SetmealWithPicVO getSetmealWithPic(Integer id);
}
