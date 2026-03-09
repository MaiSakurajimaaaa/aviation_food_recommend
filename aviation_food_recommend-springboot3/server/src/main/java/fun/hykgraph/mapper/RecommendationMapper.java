package fun.hykgraph.mapper;

import fun.hykgraph.vo.PendingRatingInfoVO;
import fun.hykgraph.vo.RecommendationDishVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Mapper
public interface RecommendationMapper {

    List<RecommendationDishVO> listCandidateDishes(@Param("flightId") Integer flightId,
                                                   @Param("mealType") Integer mealType,
                                                   @Param("flavor") String flavor,
                                                   @Param("limit") Integer limit);

    void insertLog(Map<String, Object> params);

    List<Map<String, Object>> listHistory(@Param("userId") Integer userId);

    List<PendingRatingInfoVO> findVisiblePendingRatings(@Param("userId") Integer userId,
                                                        @Param("now") LocalDateTime now);

    List<Map<String, Object>> findEndedManualSelectionsWithoutRating(@Param("userId") Integer userId,
                                                                      @Param("now") LocalDateTime now);

    Integer upsertFlightRatingTask(Map<String, Object> params);

    Integer deferFlightRating(@Param("userId") Integer userId,
                              @Param("flightId") Integer flightId,
                              @Param("nextRemindAt") LocalDateTime nextRemindAt,
                              @Param("now") LocalDateTime now);

    Integer submitFlightRating(@Param("userId") Integer userId,
                               @Param("flightId") Integer flightId,
                               @Param("rating") Integer rating,
                               @Param("now") LocalDateTime now);

    Integer syncSubmittedLogRating(@Param("userId") Integer userId,
                                   @Param("flightId") Integer flightId,
                                   @Param("rating") Integer rating);

    List<Map<String, Object>> listRecentLogs(@Param("days") Integer days);

    List<Map<String, Object>> topDishes(@Param("limit") Integer limit,
                                        @Param("startTime") LocalDateTime startTime,
                                        @Param("endTime") LocalDateTime endTime);

    Map<String, Object> dashboard();

    Integer insertMealSelection(Map<String, Object> params);

    Integer updateMealSelectionUpdateTime(@Param("userId") Integer userId,
                                          @Param("flightId") Integer flightId,
                                          @Param("updateTime") LocalDateTime updateTime);

    Integer updateMealSelectionStatusAndUpdateTime(@Param("userId") Integer userId,
                                                   @Param("flightId") Integer flightId,
                                                   @Param("status") Integer status,
                                                   @Param("updateTime") LocalDateTime updateTime);

    Integer existsMealSelection(@Param("userId") Integer userId, @Param("flightId") Integer flightId);

    Map<String, Object> latestManualSelection(@Param("userId") Integer userId, @Param("flightId") Integer flightId);

    Integer updateLatestManualRating(@Param("userId") Integer userId,
                                     @Param("flightId") Integer flightId,
                                     @Param("rating") Integer rating);

    List<Map<String, Object>> listExpiredFlights(@Param("now") LocalDateTime now);

    List<Map<String, Object>> listUsersWithoutSelectionByFlightId(@Param("flightId") Integer flightId);

    List<Map<String, Object>> exceptionUsers();

    List<Map<String, Object>> preferenceTags(@Param("userId") Integer userId);

    Integer countReminderLog(@Param("flightId") Integer flightId,
                             @Param("remindType") String remindType,
                             @Param("flightDate") String flightDate);

    Integer insertReminderLog(@Param("flightId") Integer flightId,
                              @Param("remindType") String remindType,
                              @Param("flightDate") String flightDate,
                              @Param("createdAt") LocalDateTime createdAt);

    Map<String, Object> ratingDashboard();

    List<Map<String, Object>> ratingTaskList(@Param("status") String status,
                                             @Param("flightNumber") String flightNumber,
                                             @Param("userKeyword") String userKeyword);

    Integer reopenRatingTask(@Param("id") Long id,
                             @Param("now") LocalDateTime now);

    Integer expireRatingTask(@Param("id") Long id,
                             @Param("now") LocalDateTime now);

    Integer deleteRatingTask(@Param("id") Long id);
}
