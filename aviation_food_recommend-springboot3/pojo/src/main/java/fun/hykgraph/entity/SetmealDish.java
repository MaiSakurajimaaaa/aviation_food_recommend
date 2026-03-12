package fun.hykgraph.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class SetmealDish implements Serializable {

    private Integer id;
    private String name;
    private Integer copies;
    private Integer setmealId;
    private Integer dishId;
}
