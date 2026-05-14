package fun.hykgraph.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class User implements Serializable {

    private Integer id;
    private String name;
    private String openid;
    private String phone;
    private Integer gender;
    private String idNumber;
    private String pic;
    private Integer preferenceCompleted;
    private String mealTypePreferences;   // JSON: meal type preferences
    private String flavorPreferences;     // comma-separated: flavor preferences

    private String dietaryNotes;          // dietary notes text
    private Integer currentFlightId;
    private Integer cabinType;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;     // last update time

}
