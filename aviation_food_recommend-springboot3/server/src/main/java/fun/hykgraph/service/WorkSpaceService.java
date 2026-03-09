package fun.hykgraph.service;

import fun.hykgraph.vo.BusinessDataVO;
import fun.hykgraph.vo.DishOverViewVO;
import fun.hykgraph.vo.OrderOverViewVO;
import fun.hykgraph.vo.SetmealOverViewVO;

import java.time.LocalDateTime;

public interface WorkSpaceService {
    BusinessDataVO getBusinessData(LocalDateTime begin, LocalDateTime end);

    OrderOverViewVO getOrderOverView();

    DishOverViewVO getDishOverView();

    SetmealOverViewVO getSetmealOverView();
}
