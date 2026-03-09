package fun.hykgraph.service;

import fun.hykgraph.dto.*;
import fun.hykgraph.result.PageResult;
import fun.hykgraph.vo.OrderStatisticsVO;
import fun.hykgraph.vo.OrderSubmitVO;
import fun.hykgraph.vo.OrderVO;

public interface OrderService {
    OrderSubmitVO submit(OrderSubmitDTO orderSubmitDTO);

    OrderVO getById(Integer id);

    PageResult userPage(int page, int pageSize, Integer status);

    void userCancelById(Integer id) throws Exception;

    void reOrder(Integer id);

    PageResult conditionSearch(OrderPageDTO orderPageDTO);

    OrderStatisticsVO statistics();

    void confirm(OrderConfirmDTO orderConfirmDTO);

    void reject(OrderRejectionDTO orderRejectionDTO);

    void cancel(OrderCancelDTO orderCancelDTO);

    void delivery(Integer id);

    void complete(Integer id);

    void reminder(Integer id);
}
