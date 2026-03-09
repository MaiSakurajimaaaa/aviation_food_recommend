package fun.hykgraph.vo;

import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
public class UserMealSelectionVO implements Serializable {
    private Integer userId;
    private String userName;
    private String idNumber;
    private String phone;
    private Integer flightId;
    private String flightNumber;
    private String departure;
    private String destination;
    private Integer orderId;
    private String orderNumber;
    private Integer orderStatus;
    private LocalDateTime orderTime;
    private Integer dishId;
    private String dishName;
    private String dishFlavor;
    private Integer dishCount;
}
