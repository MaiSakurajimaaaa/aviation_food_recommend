package fun.hykgraph.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class FlightPassengerDTO implements Serializable {
    private Integer id;
    /** 1-新用户录入，2-老用户搜索选择 */
    private Integer sourceType;
    /** 老用户模式下选择的客户ID */
    private Integer existingUserId;
    private Integer flightId;
    private String name;
    private String idNumber;
    private String phone;
    private Integer gender;
    private Integer preferenceCompleted;
    private Integer cabinType;
}
