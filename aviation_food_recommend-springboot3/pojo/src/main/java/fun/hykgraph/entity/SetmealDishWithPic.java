package fun.hykgraph.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class SetmealDishWithPic implements Serializable {

    private Integer id;
    private String name;
    private Integer copies;
    private String pic;
    private Integer setmealId;
    private Integer dishId;
}
