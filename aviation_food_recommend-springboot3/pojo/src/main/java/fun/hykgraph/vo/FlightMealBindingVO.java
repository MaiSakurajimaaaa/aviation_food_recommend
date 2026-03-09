package fun.hykgraph.vo;

import lombok.Data;

import java.io.Serializable;

@Data
public class FlightMealBindingVO implements Serializable {
    private Integer id;
    private Integer flightId;
    private String flightNumber;
    private String departure;
    private String destination;
    private Integer dishId;
    private String dishName;
    private Integer dishStatus;
    private Integer dishSource;
    private Integer sort;
}
