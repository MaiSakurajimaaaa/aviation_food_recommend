package fun.hykgraph.mapper;

import com.github.pagehelper.Page;
import fun.hykgraph.dto.GoodsSalesDTO;
import fun.hykgraph.dto.OrderPageDTO;
import fun.hykgraph.entity.Order;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Mapper
public interface OrderMapper {

    void insert(Order order);

    @Select("select * from orders where id = #{id}")
    Order getById(Integer id);

    Page<Order> page(OrderPageDTO orderPageDTO);

    void update(Order order);

    @Select("select count(id) from orders where status = #{status}")
    Integer countByStatus(Integer status);

    Double sumByMap(Map map);

    Integer countByMap(Map map);

    List<GoodsSalesDTO> getSalesTop10(LocalDateTime beginTime, LocalDateTime endTime);
}
