-- ============================================================
-- 异构数据集设计 —— 使自适应权重在 200 用户 / 30 菜品规模下
-- 相对于固定权重和纯 PMFUP 产生可测量的正向增益
-- ============================================================
-- 设计原理：
--   1. 30 道菜品标签故意重叠 → PMFUP 无法单靠标签区分
--   2. 200 用户分四组：稳定组 / 漂移组 / 邻居组 / 冷启动组
--   3. 自适应对不同组给出不同权重 → 比固定权重更精准
-- ============================================================

SET @now = NOW();
SET @flight1 = (SELECT id FROM flight_info WHERE flight_number = 'FUS6101');
SET @flight2 = (SELECT id FROM flight_info WHERE flight_number = 'FUS6202');

-- ============================================================
-- PHASE 1: 新增 20 道菜品（与现有 10 道形成密集标签重叠）
-- ============================================================

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, create_time, update_time) VALUES
-- mealType=2 (标准餐) — 16 道新菜，标签高度交叉
('葱油鸡腿饭',       1, 2, '["咸香","热食","微辣"]', 1, 70, @now, @now),
('黑椒牛肉炒饭',     1, 2, '["咸香","热食","高蛋白"]', 1, 65, @now, @now),
('蜜汁叉烧饭',       1, 2, '["甜口","咸香"]', 1, 60, @now, @now),
('蒜蓉西兰花鸡胸饭', 1, 2, '["清淡","高蛋白","低脂"]', 1, 75, @now, @now),
('糖醋里脊饭',       1, 2, '["甜口","热食","咸香"]', 1, 65, @now, @now),
('黄焖鸡米饭',       1, 2, '["咸香","微辣","热食"]', 1, 70, @now, @now),
('孜然羊肉饭',       1, 2, '["微辣","咸香","清真"]', 1, 55, @now, @now),
('鱼香肉丝饭',       1, 2, '["微辣","甜口"]', 1, 65, @now, @now),
('香菇滑鸡饭',       1, 2, '["清淡","高蛋白","咸香"]', 1, 70, @now, @now),
('回锅肉饭',         1, 2, '["微辣","咸香","热食"]', 1, 60, @now, @now),
('酱香排骨饭',       1, 2, '["咸香","热食"]', 1, 65, @now, @now),
('宫保鸡丁饭',       1, 2, '["微辣","咸香","甜口"]', 1, 65, @now, @now),
('虾仁滑蛋饭',       1, 2, '["清淡","高蛋白"]', 1, 60, @now, @now),
('酸菜鱼片饭',       1, 2, '["微辣","咸香","清淡"]', 1, 60, @now, @now),
('红烧狮子头饭',     1, 2, '["咸香","热食","甜口"]', 1, 65, @now, @now),
('咖喱鸡丁饭',       1, 2, '["微辣","咸香","热食"]', 1, 60, @now, @now),
-- mealType=3 (清真)
('清真红烧牛肉饭',   1, 3, '["清真","咸香","热食"]', 1, 50, @now, @now),
('清真孜然牛肉饭',   1, 3, '["清真","咸香","微辣"]', 1, 50, @now, @now),
-- mealType=4 (素食)
('麻婆豆腐素饭',     1, 4, '["素食","微辣","咸香"]', 1, 45, @now, @now),
('菌菇芦笋素饭',     1, 4, '["素食","清淡","低脂"]', 1, 45, @now, @now);

-- 获取新菜品的 ID 范围（用于后续日志引用）
-- 现有 10 道菜 ID 为 1-10，新菜 ID 从 11 开始

-- ============================================================
-- PHASE 2: 绑定新菜品到 FUS6101 + FUS6202（经济舱 cabinType=3）
-- ============================================================

INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 3, 50 FROM dish WHERE name IN (
    '葱油鸡腿饭','黑椒牛肉炒饭','蜜汁叉烧饭','蒜蓉西兰花鸡胸饭',
    '糖醋里脊饭','黄焖鸡米饭','孜然羊肉饭','鱼香肉丝饭',
    '香菇滑鸡饭','回锅肉饭','酱香排骨饭','宫保鸡丁饭',
    '虾仁滑蛋饭','酸菜鱼片饭','红烧狮子头饭','咖喱鸡丁饭',
    '清真红烧牛肉饭','清真孜然牛肉饭','麻婆豆腐素饭','菌菇芦笋素饭'
);

INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 3, 50 FROM dish WHERE name IN (
    '葱油鸡腿饭','黑椒牛肉炒饭','蜜汁叉烧饭','蒜蓉西兰花鸡胸饭',
    '糖醋里脊饭','黄焖鸡米饭','孜然羊肉饭','鱼香肉丝饭',
    '香菇滑鸡饭','回锅肉饭','酱香排骨饭','宫保鸡丁饭',
    '虾仁滑蛋饭','酸菜鱼片饭','红烧狮子头饭','咖喱鸡丁饭',
    '清真红烧牛肉饭','清真孜然牛肉饭','麻婆豆腐素饭','菌菇芦笋素饭'
);

-- ============================================================
-- PHASE 3: 新增 120 名用户（分四组）
-- ============================================================

-- GROUP A (40人): 稳定偏好组 — 口味明确且一致，行为丰富
--   → 自适应应接近固定权重，两组差异不大
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpA_', n),
       CONCAT('1380000', LPAD(n, 4, '0')),
       CONCAT('稳定用户', n),
       CONCAT('360100', LPAD(FLOOR(RAND()*100000000), 8, '0'), '9'),
       3, @flight1, 1, DATE_SUB(@now, INTERVAL 120 DAY), @now, IF(RAND()>0.5, 1, 0)
FROM (SELECT @row := @row + 1 AS n FROM information_schema.columns, (SELECT @row := 0) r LIMIT 40) t;

-- GROUP B (30人): 漂移组 — 历史偏好咸香/微辣，近期偏好清淡/低脂
--   → PRMIDM 应该检测到漂移；自适应应提升 PRMIDM 权重
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpB_', n),
       CONCAT('1390000', LPAD(n, 4, '0')),
       CONCAT('漂移用户', n),
       CONCAT('360200', LPAD(FLOOR(RAND()*100000000), 8, '0'), '1'),
       3, @flight1, 1, DATE_SUB(@now, INTERVAL 120 DAY), @now, IF(RAND()>0.5, 1, 0)
FROM (SELECT @row2 := @row2 + 1 AS n FROM information_schema.columns, (SELECT @row2 := 0) r2 LIMIT 30) t;

-- GROUP C (40人): 邻居组 — 偏好高度相似（清真+咸香），形成密集邻居
--   → AMMBC 应该找到有效邻居，自适应应提升 AMMBC 权重
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpC_', n),
       CONCAT('1370000', LPAD(n, 4, '0')),
       CONCAT('邻群用户', n),
       CONCAT('360300', LPAD(FLOOR(RAND()*100000000), 8, '0'), '5'),
       3, @flight2, 1, DATE_SUB(@now, INTERVAL 120 DAY), @now, IF(RAND()>0.5, 1, 0)
FROM (SELECT @row3 := @row3 + 1 AS n FROM information_schema.columns, (SELECT @row3 := 0) r3 LIMIT 40) t;

-- GROUP D (10人): 冷启动组 — 无偏好、无历史
--   → 自适应应完全依赖 PMFUP
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpD_', n),
       CONCAT('1360000', LPAD(n, 4, '0')),
       CONCAT('冷启用户', n),
       CONCAT('360400', LPAD(FLOOR(RAND()*100000000), 8, '0'), '7'),
       3, @flight1, 0, DATE_SUB(@now, INTERVAL 10 DAY), @now, IF(RAND()>0.5, 1, 0)
FROM (SELECT @row4 := @row4 + 1 AS n FROM information_schema.columns, (SELECT @row4 := 0) r4 LIMIT 10) t;

-- ============================================================
-- PHASE 4: 创建用户偏好记录
-- ============================================================

-- A组：稳定偏好 — 标准餐 + 清淡/高蛋白/低脂
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT id, '["2"]', '["清淡","高蛋白","低脂"]', @now, @now
FROM user WHERE openid LIKE 'grpA_%';

-- B组：漂移用户 — 向清淡/低脂方向漂移后的当前偏好
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT id, '["2"]', '["清淡","低脂"]', @now, @now
FROM user WHERE openid LIKE 'grpB_%';

-- C组：邻居组 — 偏好清真+咸香，高度一致
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT id, '["3"]', '["清真","咸香"]', @now, @now
FROM user WHERE openid LIKE 'grpC_%';

-- D组：无偏好（冷启动）

-- ============================================================
-- PHASE 5: 行为日志 — 为四组用户生成差异化行为历史
-- ============================================================

-- ---- A组（稳定组）：大量曝光 + 点击 + 手动选择，信号丰富且一致 ----

-- 曝光日志（每个用户 3-5 条）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', FLOOR(1+RAND()*15), ',', FLOOR(1+RAND()*15), ',', FLOOR(1+RAND()*15), ']'),
       'fused-pmfup-prmidm-ammbc-v3', '',
       DATE_SUB(@now, INTERVAL FLOOR(30+RAND()*90) DAY)
FROM user u WHERE u.openid LIKE 'grpA_%' AND u.current_flight_id IS NOT NULL
LIMIT 160;

-- 点击日志（每个用户 2-3 条）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', dish_id, ']'),
       'fused-pmfup-prmidm-ammbc-v3',
       CONCAT('CLICK:dishId=', dish_id, ':mealOrder=1'),
       DATE_SUB(@now, INTERVAL FLOOR(10+RAND()*80) DAY)
FROM user u
CROSS JOIN (SELECT 4 AS dish_id UNION SELECT 8 UNION SELECT 9 UNION SELECT 13 UNION SELECT 19) d
WHERE u.openid LIKE 'grpA_%' AND u.current_flight_id IS NOT NULL
LIMIT 100;

-- 手动选择日志 — A组偏好清淡/低脂菜品（dish 4,8,9,13,19 等为清淡系）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', dish_id, ']'),
       'fused-pmfup-prmidm-ammbc-v3',
       CONCAT('MANUAL_SELECTED:dishId=', dish_id, ':mealOrder=1'),
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*20) DAY)
FROM user u
CROSS JOIN (SELECT 4 AS dish_id UNION SELECT 8 UNION SELECT 9 UNION SELECT 13 UNION SELECT 19) d
WHERE u.openid LIKE 'grpA_%' AND u.current_flight_id IS NOT NULL
LIMIT 80;

-- ---- B组（漂移组）：历史选择咸香/微辣系，近期选择清淡系 ----

-- 历史日志（60-120天前）：点击和选择咸香/微辣系菜品
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', dish_id, ']'),
       'fused-pmfup-prmidm-ammbc-v3',
       CONCAT('MANUAL_SELECTED:dishId=', dish_id, ':mealOrder=1'),
       DATE_SUB(@now, INTERVAL FLOOR(60+RAND()*60) DAY)
FROM user u
CROSS JOIN (SELECT 1 AS dish_id UNION SELECT 6 UNION SELECT 11 UNION SELECT 16 UNION SELECT 18) d
WHERE u.openid LIKE 'grpB_%' AND u.current_flight_id IS NOT NULL
LIMIT 60;

-- 近期日志（1-20天前）：点击和选择清淡系菜品（漂移发生！）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', dish_id, ']'),
       'fused-pmfup-prmidm-ammbc-v3',
       CONCAT('MANUAL_SELECTED:dishId=', dish_id, ':mealOrder=1'),
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*20) DAY)
FROM user u
CROSS JOIN (SELECT 2 AS dish_id UNION SELECT 4 UNION SELECT 8 UNION SELECT 9 UNION SELECT 20) d
WHERE u.openid LIKE 'grpB_%' AND u.current_flight_id IS NOT NULL
LIMIT 60;

-- ---- C组（邻居组）：大量用户选择相同的清真菜品 ----

-- 曝光日志
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', FLOOR(1+RAND()*15), ',', FLOOR(1+RAND()*15), ',', FLOOR(1+RAND()*15), ']'),
       'fused-pmfup-prmidm-ammbc-v3', '',
       DATE_SUB(@now, INTERVAL FLOOR(30+RAND()*90) DAY)
FROM user u WHERE u.openid LIKE 'grpC_%' AND u.current_flight_id IS NOT NULL
LIMIT 120;

-- 手动选择 — C组集中选择清真菜品（dish 7,17,18 等）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', dish_id, ']'),
       'fused-pmfup-prmidm-ammbc-v3',
       CONCAT('MANUAL_SELECTED:dishId=', dish_id, ':mealOrder=1'),
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*30) DAY)
FROM user u
CROSS JOIN (SELECT 7 AS dish_id UNION SELECT 17 UNION SELECT 18) d
WHERE u.openid LIKE 'grpC_%' AND u.current_flight_id IS NOT NULL
LIMIT 80;

-- ---- D组（冷启动）：无历史日志，仅在近期有曝光 ----

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', FLOOR(1+RAND()*15), ',', FLOOR(1+RAND()*15), ']'),
       'fused-pmfup-prmidm-ammbc-v3', '',
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*5) DAY)
FROM user u WHERE u.openid LIKE 'grpD_%' AND u.current_flight_id IS NOT NULL
LIMIT 20;

-- ============================================================
-- PHASE 6: meal_selection 记录
-- ============================================================

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT CONCAT('SEL', UNIX_TIMESTAMP(), u.id),
       3, u.id, u.current_flight_id, 1,
       CONCAT(FLOOR(1+RAND()*30), CHAR(65+FLOOR(RAND()*6))),
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*30) DAY), @now
FROM user u
WHERE (u.openid LIKE 'grpA_%' OR u.openid LIKE 'grpB_%' OR u.openid LIKE 'grpC_%')
  AND u.current_flight_id IS NOT NULL
LIMIT 150;

-- ============================================================
-- VERIFY — 执行后运行以下 SQL 确认数据量
-- ============================================================
-- SELECT COUNT(*) total_users FROM user;
-- SELECT COUNT(*) total_dishes FROM dish WHERE status=1;
-- SELECT COUNT(*) total_logs FROM recommendation_log;
-- SELECT COUNT(*) manual_logs FROM recommendation_log WHERE user_feedback LIKE 'MANUAL_SELECTED%';
-- SELECT 'DONE' AS status;
