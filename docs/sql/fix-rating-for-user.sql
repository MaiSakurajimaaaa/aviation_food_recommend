-- ====================================
-- 为"胡屿科"构造评分任务测试数据
-- ====================================

SET @user_name = '胡屿科';
SET @now = NOW();

-- 从评论和之前的对话中查找 user_id
SELECT id, name, current_flight_id
FROM user
WHERE name = @user_name
ORDER BY id DESC LIMIT 3;

-- 1. 确保航班有 arrival_time（评分任务的前提条件）
--    将最近的航班的 arrival_time 设置为过去时间
UPDATE flight_info
SET arrival_time = DATE_SUB(@now, INTERVAL 2 HOUR),
    flight_status = 3
WHERE id = (
    SELECT current_flight_id FROM user WHERE name = @user_name ORDER BY id DESC LIMIT 1
);

-- 2. 检查用户是否有选餐记录（MANUAL_SELECTED）
SELECT rl.id, rl.user_id, rl.flight_id, rl.user_feedback, rl.user_rating, rl.create_time
FROM recommendation_log rl
JOIN user u ON u.id = rl.user_id
WHERE u.name = @user_name
  AND (rl.user_feedback LIKE 'MANUAL_SELECTED%' OR rl.user_feedback LIKE 'AUTO_SELECTED%')
ORDER BY rl.id DESC LIMIT 5;

-- 3. 如果上面查询为空，插入一条模拟选餐记录
--    先确认 user 和 flight 数据
SELECT u.id AS user_id, u.current_flight_id, fi.flight_number, fi.arrival_time
FROM user u
LEFT JOIN flight_info fi ON fi.id = u.current_flight_id
WHERE u.name = @user_name;

-- 4. 手动插入选餐记录（用下面的模板，替换 <user_id> 和 <flight_id>）
-- INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
-- VALUES (<user_id>, <flight_id>, '[1]', 'fused-pmfup-prmidm-ammbc-v3',
--         'MANUAL_SELECTED:dishId=1:mealOrder=1',
--         DATE_SUB(@now, INTERVAL 3 HOUR));

-- 5. 清理已存在的评分任务（如有），让系统重新生成
-- DELETE FROM flight_service_rating
-- WHERE user_id = <user_id> AND flight_id = <flight_id>;
