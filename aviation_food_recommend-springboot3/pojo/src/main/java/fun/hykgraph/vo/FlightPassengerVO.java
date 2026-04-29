package fun.hykgraph.vo;

import lombok.Data;

import java.io.Serializable;

@Data
public class FlightPassengerVO implements Serializable {

    private Integer userId;
    private String name;
    private String idNumber;
    private Integer age;
    private String phone;
    private String gender;
    private Integer preferenceCompleted;
    private String bindStatus;
    private String mealSelected;
    private Integer cabinType;
    private String cabinTypeLabel;
    private Integer flightId;
    private String flightNumber;
    private String departure;
    private String destination;
}
