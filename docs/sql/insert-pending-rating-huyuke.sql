-- ====================================
-- 为胡屿科(user_id=10) FUS6666 插入待评分记录（截图用）
-- ====================================

-- 1. 先找到 FUS6666 的 flight_id
SELECT id FROM flight_info WHERE flight_number = 'FUS6666';

-- 2. 确保有选餐记录（评分任务的 source_log_id 依赖它）
--    如果查不到，插入一条
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT 10, id, '[1]', 'fused-pmfup-prmidm-ammbc-v3',
       'MANUAL_SELECTED:dishId=1:mealOrder=1', DATE_SUB(NOW(), INTERVAL 5 HOUR)
FROM flight_info
WHERE flight_number = 'FUS6666'
  AND NOT EXISTS (
    SELECT 1 FROM recommendation_log
    WHERE user_id = 10 AND flight_id = flight_info.id
      AND user_feedback LIKE 'MANUAL_SELECTED%'
  );

-- 3. 获取刚插入/已存在的选餐记录 ID
SELECT rl.id AS source_log_id, fi.flight_number
FROM recommendation_log rl
JOIN flight_info fi ON fi.id = rl.flight_id
WHERE rl.user_id = 10 AND fi.flight_number = 'FUS6666'
  AND rl.user_feedback LIKE 'MANUAL_SELECTED%'
ORDER BY rl.id DESC LIMIT 1;

-- 4. 插入待评分任务（用上面查到的 source_log_id 替换）
INSERT INTO flight_service_rating
(user_id, flight_id, source_log_id, rating_status, first_visible_at, last_visible_at,
 next_remind_at, defer_count, expire_at, channel, create_time, update_time)
SELECT
    10,
    fi.id,
    (SELECT rl.id FROM recommendation_log rl
     WHERE rl.user_id = 10 AND rl.flight_id = fi.id
       AND rl.user_feedback LIKE 'MANUAL_SELECTED%'
     ORDER BY rl.id DESC LIMIT 1),
    'PENDING',
    NOW(), NOW(), NOW(), 0, DATE_ADD(NOW(), INTERVAL 7 DAY), 'miniapp', NOW(), NOW()
FROM flight_info fi
WHERE fi.flight_number = 'FUS6666'
ON DUPLICATE KEY UPDATE
    rating_status = 'PENDING',
    rating_score = null,
    submitted_at = null,
    first_visible_at = NOW(),
    last_visible_at = NOW(),
    next_remind_at = NOW(),
    defer_count = 0,
    expire_at = DATE_ADD(NOW(), INTERVAL 7 DAY),
    update_time = NOW();

-- 5. 验证
SELECT fr.*, fi.flight_number, fi.departure, fi.destination, fi.arrival_time
FROM flight_service_rating fr
JOIN flight_info fi ON fi.id = fr.flight_id
WHERE fr.user_id = 10;
