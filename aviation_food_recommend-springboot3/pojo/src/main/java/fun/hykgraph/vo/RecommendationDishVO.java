package fun.hykgraph.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RecommendationDishVO implements Serializable {

    private Integer dishId;
    private String dishName;
    private String pic;
    private String detail;
    private Integer mealType;
    private String flavorTags;
    private String routeDeparture;
    private String routeDestination;
    private Double score;
    private String explainReason;
    private Integer fallbackLevel;
}
