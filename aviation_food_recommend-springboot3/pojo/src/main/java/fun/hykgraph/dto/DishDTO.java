package fun.hykgraph.dto;

import fun.hykgraph.entity.DishFlavor;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DishDTO implements Serializable {

    private Integer id;
    private String name;
    private String pic;
    private String detail;
    private String status;
    private Integer stock;
    private Integer categoryId;
    private Integer mealType;
    private String flavorTags;
    // 多种口味，包括温度，忌口等(每种口味又对应一个列表)，且数据在口味表中而不是在Dish里，口味表有外键关联Dish
    private List<DishFlavor> flavors = new ArrayList<>();

}
