package fun.hykgraph.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class FlightAnnouncement implements Serializable {

    private Integer id;
    private Integer flightId;
    private String title;
    private String content;
    private Integer status;
    private Integer createUser;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
