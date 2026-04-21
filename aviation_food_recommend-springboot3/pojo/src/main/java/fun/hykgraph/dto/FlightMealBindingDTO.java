package fun.hykgraph.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class FlightMealBindingDTO implements Serializable {
    private Integer id;
    private String flightNumber;
    private Integer dishId;
    private Integer dishSource;
    private Integer sort;
    private Integer cabinType;
}
