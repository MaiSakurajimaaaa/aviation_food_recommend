package fun.hykgraph.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class FlightPassengerDTO implements Serializable {
    private Integer id;
    private Integer flightId;
    private String name;
    private String idNumber;
    private String phone;
    private Integer gender;
    private Integer preferenceCompleted;
}
