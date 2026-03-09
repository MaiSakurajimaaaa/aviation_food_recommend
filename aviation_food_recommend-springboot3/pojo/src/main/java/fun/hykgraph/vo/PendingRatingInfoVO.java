package fun.hykgraph.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class PendingRatingInfoVO {

    private Long ratingTaskId;
    private Long logId;
    private Integer flightId;
    private String ratingStatus;
    private Integer deferCount;
    private LocalDateTime nextRemindAt;
    private LocalDateTime expireAt;
    private Integer dishId;
    private String flightNumber;
    private String departure;
    private String destination;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;
    private String recommendedDishes;
}
