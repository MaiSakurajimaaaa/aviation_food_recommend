package fun.hykgraph.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserPreference implements Serializable {

    private Integer id;
    private Integer userId;
    private String mealTypePreferences;
    private String flavorPreferences;
    private String allergens;
    private String dietaryNotes;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
