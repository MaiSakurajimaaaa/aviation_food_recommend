-- 目的：补强答辩“多元融合推荐算法”演示数据（幂等）
-- 覆盖：多餐次行为、点击/改选、评分分布(1-5星)、用户偏好多样性

USE aviation_food_recommend;

SET NAMES utf8mb4;

SET @now = NOW();
SET @alg = 'fused-pmfup-prmidm-ammbc-v1';
SET @tag = 'DEMOBOOST20260421';

-- 1) 基础ID（优先 FUS6101，兜底到任意可用航班）
SELECT id INTO @f_demo FROM flight_info WHERE flight_number = 'FUS6101' ORDER BY id DESC LIMIT 1;
SET @f_demo = IFNULL(@f_demo, (SELECT id FROM flight_info WHERE status = 1 AND IFNULL(meal_count, 1) >= 2 ORDER BY id LIMIT 1));
SET @f_demo = IFNULL(@f_demo, (SELECT id FROM flight_info WHERE status = 1 ORDER BY id LIMIT 1));

SELECT id INTO @d_a FROM dish WHERE name = '低脂鸡胸藜麦饭' LIMIT 1;
SELECT id INTO @d_b FROM dish WHERE name = '经典红烧牛腩饭' LIMIT 1;
SELECT id INTO @d_c FROM dish WHERE name = '香烤鳕鱼时蔬饭' LIMIT 1;
SELECT id INTO @d_d FROM dish WHERE name = '川香麻辣牛肉面' LIMIT 1;
SELECT id INTO @d_e FROM dish WHERE name = '低脂水果酸奶杯' LIMIT 1;
SELECT id INTO @d_f FROM dish WHERE name = '能量火腿三明治' LIMIT 1;
SELECT id INTO @d_g FROM dish WHERE name = '全素菌菇烩饭' LIMIT 1;

SET @d_a = IFNULL(@d_a, (SELECT id FROM dish WHERE status = 1 ORDER BY id ASC LIMIT 1));
SET @d_b = IFNULL(@d_b, (SELECT id FROM dish WHERE status = 1 ORDER BY id ASC LIMIT 1 OFFSET 1));
SET @d_c = IFNULL(@d_c, (SELECT id FROM dish WHERE status = 1 ORDER BY id ASC LIMIT 1 OFFSET 2));
SET @d_d = IFNULL(@d_d, @d_b);
SET @d_e = IFNULL(@d_e, @d_a);
SET @d_f = IFNULL(@d_f, @d_c);
SET @d_g = IFNULL(@d_g, @d_a);

-- 2) 演示用户模板
DROP TEMPORARY TABLE IF EXISTS tmp_demo_fusion_users;
CREATE TEMPORARY TABLE tmp_demo_fusion_users (
  idx INT PRIMARY KEY,
  openid VARCHAR(64) NOT NULL,
  name VARCHAR(32) NOT NULL,
  cabin_type TINYINT NOT NULL,
  meal_type_pref VARCHAR(32) NOT NULL,
  flavor_pref VARCHAR(64) NOT NULL,
  rating_seed TINYINT NOT NULL
);

INSERT INTO tmp_demo_fusion_users (idx, openid, name, cabin_type, meal_type_pref, flavor_pref, rating_seed) VALUES
(1,  'demo_fusion_u01', '融合样本01', 1, '[2]', '["清淡","高蛋白"]', 5),
(2,  'demo_fusion_u02', '融合样本02', 1, '[2]', '["咸香","热食"]', 4),
(3,  'demo_fusion_u03', '融合样本03', 1, '[4]', '["甜口","低脂"]', 3),
(4,  'demo_fusion_u04', '融合样本04', 1, '[1]', '["甜口","不辣"]', 2),
(5,  'demo_fusion_u05', '融合样本05', 2, '[2]', '["微辣","咸香"]', 1),
(6,  'demo_fusion_u06', '融合样本06', 2, '[3]', '["清真","咸香"]', 5),
(7,  'demo_fusion_u07', '融合样本07', 2, '[4]', '["素食","清淡"]', 4),
(8,  'demo_fusion_u08', '融合样本08', 2, '[2]', '["高蛋白","清淡"]', 3),
(9,  'demo_fusion_u09', '融合样本09', 3, '[2]', '["咸香","热食"]', 2),
(10, 'demo_fusion_u10', '融合样本10', 3, '[4]', '["低脂","清淡"]', 1),
(11, 'demo_fusion_u11', '融合样本11', 3, '[1]', '["甜口","不辣"]', 5),
(12, 'demo_fusion_u12', '融合样本12', 3, '[2]', '["微辣","高蛋白"]', 4);

-- 3) upsert 用户
INSERT INTO user (
  openid, name, phone, id_number, preference_completed, current_flight_id, cabin_type, gender, pic, create_time
)
SELECT
  t.openid,
  t.name,
  CONCAT('1390000', LPAD(t.idx, 4, '0')),
  CONCAT('51010119900101', LPAD(t.idx, 3, '0'), 'X'),
  1,
  @f_demo,
  t.cabin_type,
  1,
  '',
  @now
FROM tmp_demo_fusion_users t
WHERE NOT EXISTS (
  SELECT 1 FROM user u
  WHERE CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
        = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
);

UPDATE user u
JOIN tmp_demo_fusion_users t
  ON CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
SET
  u.name = t.name,
  u.preference_completed = 1,
  u.current_flight_id = @f_demo,
  u.cabin_type = t.cabin_type
WHERE t.openid LIKE 'demo_fusion_u%';

-- 4) upsert 偏好
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, dietary_notes, create_time, update_time)
SELECT
  u.id,
  t.meal_type_pref,
  t.flavor_pref,
  CONCAT('答辩融合样本-', LPAD(t.idx, 2, '0')),
  @now,
  @now
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
LEFT JOIN user_preference up ON up.user_id = u.id
WHERE up.user_id IS NULL;

UPDATE user_preference up
JOIN user u ON u.id = up.user_id
JOIN tmp_demo_fusion_users t
  ON CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
SET
  up.meal_type_preferences = t.meal_type_pref,
  up.flavor_preferences = t.flavor_pref,
  up.dietary_notes = CONCAT('答辩融合样本-', LPAD(t.idx, 2, '0')),
  up.update_time = @now
WHERE t.openid LIKE 'demo_fusion_u%';

-- 5) 清理旧的演示增强日志/选餐（仅清理本tag）
DELETE FROM recommendation_log
WHERE algorithm_type = @alg
  AND user_feedback LIKE CONCAT('%', @tag, '%');

DELETE ms
FROM meal_selection ms
JOIN user u ON u.id = ms.user_id
JOIN tmp_demo_fusion_users t
  ON CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
WHERE ms.flight_id = @f_demo
  AND ms.seat_number = 'DEMO';

-- 6) 插入曝光 + 点击 + 手动选择(第1餐)
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
  u.id,
  @f_demo,
  CONCAT('[', @d_a, ',', @d_b, ',', @d_c, ']'),
  @alg,
  CONCAT(
    'CLICK:dishId=',
    CASE MOD(t.idx, 3)
      WHEN 1 THEN @d_a
      WHEN 2 THEN @d_b
      ELSE @d_c
    END,
    ':mealOrder=1:', @tag
  ),
  DATE_SUB(@now, INTERVAL (240 - t.idx * 5) MINUTE)
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci;

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT
  u.id,
  @f_demo,
  CONCAT('[', @d_a, ',', @d_b, ',', @d_c, ',', @d_d, ']'),
  @alg,
  t.rating_seed,
  CONCAT(
    'MANUAL_SELECTED:dishId=',
    CASE
      WHEN t.idx <= 4 THEN @d_a
      WHEN t.idx <= 8 THEN @d_b
      ELSE @d_c
    END,
    ':mealOrder=1:', @tag
  ),
  DATE_SUB(@now, INTERVAL (200 - t.idx * 4) MINUTE)
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci;

-- 7) 第2餐行为（前10位用户）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
  u.id,
  @f_demo,
  CONCAT('[', @d_e, ',', @d_f, ',', @d_g, ']'),
  @alg,
  CONCAT(
    'CLICK:dishId=',
    CASE MOD(t.idx, 3)
      WHEN 1 THEN @d_e
      WHEN 2 THEN @d_f
      ELSE @d_g
    END,
    ':mealOrder=2:', @tag
  ),
  DATE_SUB(@now, INTERVAL (140 - t.idx * 3) MINUTE)
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
WHERE t.idx <= 10;

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT
  u.id,
  @f_demo,
  CONCAT('[', @d_e, ',', @d_f, ',', @d_g, ']'),
  @alg,
  CASE
    WHEN t.idx <= 2 THEN 1
    WHEN t.idx <= 4 THEN 2
    WHEN t.idx <= 6 THEN 3
    WHEN t.idx <= 8 THEN 4
    ELSE 5
  END,
  CONCAT(
    'MANUAL_SELECTED:dishId=',
    CASE
      WHEN t.idx <= 4 THEN @d_e
      WHEN t.idx <= 8 THEN @d_f
      ELSE @d_g
    END,
    ':mealOrder=2:', @tag
  ),
  DATE_SUB(@now, INTERVAL (110 - t.idx * 2) MINUTE)
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
WHERE t.idx <= 10;

-- 一部分第2餐改选（用于展示兴趣漂移/动态更新）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
  u.id,
  @f_demo,
  CONCAT('[', @d_e, ',', @d_f, ',', @d_g, ']'),
  @alg,
  CONCAT(
    'MANUAL_SELECTED_UPDATE:dishId=',
    CASE MOD(t.idx, 3)
      WHEN 1 THEN @d_f
      WHEN 2 THEN @d_g
      ELSE @d_e
    END,
    ':mealOrder=2:', @tag
  ),
  DATE_SUB(@now, INTERVAL (70 - t.idx) MINUTE)
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
WHERE t.idx <= 4;

-- 8) 自动分配样本（用于对比人工与自动）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
  u.id,
  @f_demo,
  CONCAT('[', @d_b, ']'),
  @alg,
  CONCAT('AUTO_SELECTED_OVERDUE:dishId=', @d_b, ':mealOrder=1:', @tag),
  DATE_SUB(@now, INTERVAL (48 - t.idx) HOUR)
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
WHERE t.idx IN (11, 12);

-- 9) 插入选餐结果（用于多餐次完成进度展示）
INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT
  CONCAT('DEMOB-20260421-M1-', u.id),
  3,
  u.id,
  @f_demo,
  1,
  'DEMO',
  DATE_SUB(@now, INTERVAL (180 - t.idx * 4) MINUTE),
  @now
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci;

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT
  CONCAT('DEMOB-20260421-M2-', u.id),
  3,
  u.id,
  @f_demo,
  2,
  'DEMO',
  DATE_SUB(@now, INTERVAL (90 - t.idx * 2) MINUTE),
  @now
FROM tmp_demo_fusion_users t
JOIN user u
  ON CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
WHERE t.idx <= 10;

-- 10) 输出体检结果（用于答辩前自检）
SELECT 'demo_fusion_users' AS metric, COUNT(*) AS val
FROM user u
JOIN tmp_demo_fusion_users t
  ON CAST(t.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
     = CAST(u.openid AS CHAR(64) CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci
UNION ALL
SELECT 'demo_logs_by_tag', COUNT(*)
FROM recommendation_log
WHERE user_feedback LIKE CONCAT('%', @tag, '%')
UNION ALL
SELECT 'demo_manual_meal_order_2', COUNT(*)
FROM recommendation_log
WHERE user_feedback LIKE CONCAT('MANUAL_SELECTED:%mealOrder=2:%', @tag, '%');

SELECT
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_feedback LIKE '%mealOrder=1%' THEN 1 ELSE 0 END) AS tag_meal_order1_logs,
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_feedback LIKE '%mealOrder=2%' THEN 1 ELSE 0 END) AS tag_meal_order2_logs,
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_rating = 1 THEN 1 ELSE 0 END) AS tag_rating_1,
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_rating = 2 THEN 1 ELSE 0 END) AS tag_rating_2,
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_rating = 3 THEN 1 ELSE 0 END) AS tag_rating_3,
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_rating = 4 THEN 1 ELSE 0 END) AS tag_rating_4,
  SUM(CASE WHEN user_feedback LIKE CONCAT('%', @tag, '%') AND user_rating = 5 THEN 1 ELSE 0 END) AS tag_rating_5
FROM recommendation_log;
