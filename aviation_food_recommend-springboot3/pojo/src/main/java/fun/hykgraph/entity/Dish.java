package fun.hykgraph.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Dish implements Serializable {

    private Integer id;
    private String name;
    private String pic;
    private String detail;
    private Integer status;
    private Integer stock;
    private Integer categoryId;
    private Integer mealType;
    private String flavorTags;
    private Integer createUser;
    private Integer updateUser;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
