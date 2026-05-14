-- ============================================================
-- 异构数据集设计 v2（修复版：子查询替代变量）
-- ============================================================
-- 前置检查：确认以下航班存在
-- SELECT id, flight_number FROM flight_info WHERE flight_number IN ('FUS6101','FUS6202');
-- 前置检查：确认现有菜品
-- SELECT id, name, flavor_tags FROM dish WHERE status=1 ORDER BY id;
-- ============================================================

SET @now = NOW();

-- ============================================================
-- PHASE 1: 清理重跑（如果之前跑过 v1 且数据混乱）
-- ============================================================

DELETE FROM meal_selection WHERE user_id IN (SELECT id FROM user WHERE openid LIKE 'grp%');
DELETE FROM recommendation_log WHERE user_id IN (SELECT id FROM user WHERE openid LIKE 'grp%');
DELETE FROM user_preference WHERE user_id IN (SELECT id FROM user WHERE openid LIKE 'grp%');
DELETE FROM user WHERE openid LIKE 'grp%';
DELETE FROM flight_route_dish WHERE dish_id IN (SELECT id FROM dish WHERE id > 10 AND name IN (
    '葱油鸡腿饭','黑椒牛肉炒饭','蜜汁叉烧饭','蒜蓉西兰花鸡胸饭','糖醋里脊饭',
    '黄焖鸡米饭','孜然羊肉饭','鱼香肉丝饭','香菇滑鸡饭','回锅肉饭',
    '酱香排骨饭','宫保鸡丁饭','虾仁滑蛋饭','酸菜鱼片饭','红烧狮子头饭','咖喱鸡丁饭',
    '清真红烧牛肉饭','清真孜然牛肉饭','麻婆豆腐素饭','菌菇芦笋素饭'
));
DELETE FROM dish WHERE id > 10 AND name IN (
    '葱油鸡腿饭','黑椒牛肉炒饭','蜜汁叉烧饭','蒜蓉西兰花鸡胸饭','糖醋里脊饭',
    '黄焖鸡米饭','孜然羊肉饭','鱼香肉丝饭','香菇滑鸡饭','回锅肉饭',
    '酱香排骨饭','宫保鸡丁饭','虾仁滑蛋饭','酸菜鱼片饭','红烧狮子头饭','咖喱鸡丁饭',
    '清真红烧牛肉饭','清真孜然牛肉饭','麻婆豆腐素饭','菌菇芦笋素饭'
);

-- ============================================================
-- PHASE 2: 新增 20 道菜品（ID 从当前最大 +1 开始）
-- ============================================================

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, create_time, update_time) VALUES
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
('清真红烧牛肉饭',   1, 3, '["清真","咸香","热食"]', 1, 50, @now, @now),
('清真孜然牛肉饭',   1, 3, '["清真","咸香","微辣"]', 1, 50, @now, @now),
('麻婆豆腐素饭',     1, 4, '["素食","微辣","咸香"]', 1, 45, @now, @now),
('菌菇芦笋素饭',     1, 4, '["素食","清淡","低脂"]', 1, 45, @now, @now);

-- ============================================================
-- PHASE 3: 航线-菜品绑定（用子查询获取 flight_id 和 dish_id）
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
-- PHASE 4: 新增 120 名用户（直接指定 flight_id，不用变量）
-- ============================================================

-- GROUP A (40人): 稳定偏好组 → FUS6101
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpA_', n), CONCAT('1380000', LPAD(n, 4, '0')),
       CONCAT('稳定用户', n), CONCAT('360100', LPAD(FLOOR(RAND()*100000000), 8, '0'), '9'),
       3, (SELECT id FROM flight_info WHERE flight_number='FUS6101'), 1,
       DATE_SUB(@now, INTERVAL 120 DAY), @now, IF(RAND()>0.5,1,0)
FROM (SELECT @row1 := @row1 + 1 AS n FROM information_schema.columns, (SELECT @row1 := 0) r LIMIT 40) t;

-- GROUP B (30人): 漂移组 → FUS6101
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpB_', n), CONCAT('1390000', LPAD(n, 4, '0')),
       CONCAT('漂移用户', n), CONCAT('360200', LPAD(FLOOR(RAND()*100000000), 8, '0'), '1'),
       3, (SELECT id FROM flight_info WHERE flight_number='FUS6101'), 1,
       DATE_SUB(@now, INTERVAL 120 DAY), @now, IF(RAND()>0.5,1,0)
FROM (SELECT @row2 := @row2 + 1 AS n FROM information_schema.columns, (SELECT @row2 := 0) r2 LIMIT 30) t;

-- GROUP C (40人): 邻居组 → FUS6202
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpC_', n), CONCAT('1370000', LPAD(n, 4, '0')),
       CONCAT('邻群用户', n), CONCAT('360300', LPAD(FLOOR(RAND()*100000000), 8, '0'), '5'),
       3, (SELECT id FROM flight_info WHERE flight_number='FUS6202'), 1,
       DATE_SUB(@now, INTERVAL 120 DAY), @now, IF(RAND()>0.5,1,0)
FROM (SELECT @row3 := @row3 + 1 AS n FROM information_schema.columns, (SELECT @row3 := 0) r3 LIMIT 40) t;

-- GROUP D (10人): 冷启动组 → FUS6101
INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
SELECT CONCAT('grpD_', n), CONCAT('1360000', LPAD(n, 4, '0')),
       CONCAT('冷启用户', n), CONCAT('360400', LPAD(FLOOR(RAND()*100000000), 8, '0'), '7'),
       3, (SELECT id FROM flight_info WHERE flight_number='FUS6101'), 0,
       DATE_SUB(@now, INTERVAL 10 DAY), @now, IF(RAND()>0.5,1,0)
FROM (SELECT @row4 := @row4 + 1 AS n FROM information_schema.columns, (SELECT @row4 := 0) r4 LIMIT 10) t;

-- ============================================================
-- PHASE 5: 用户偏好记录
-- ============================================================

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT u.id, '["2"]', '["清淡","高蛋白","低脂"]', @now, @now
FROM user u WHERE u.openid LIKE 'grpA_%';

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT u.id, '["2"]', '["清淡","低脂"]', @now, @now
FROM user u WHERE u.openid LIKE 'grpB_%';

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT u.id, '["3"]', '["清真","咸香"]', @now, @now
FROM user u WHERE u.openid LIKE 'grpC_%';

-- ============================================================
-- PHASE 6: 行为日志
-- ============================================================

-- A组曝光
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',FLOOR(1+RAND()*15),',',FLOOR(1+RAND()*15),',',FLOOR(1+RAND()*15),']'),
       'fused-pmfup-prmidm-ammbc-v3', '',
       DATE_SUB(@now, INTERVAL FLOOR(30+RAND()*90) DAY)
FROM user u WHERE u.openid LIKE 'grpA_%' AND u.current_flight_id IS NOT NULL
LIMIT 160;

-- A组手动选择（清淡系）
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

-- A组点击
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

-- B组历史（60-120天前，咸香/微辣系）→ 漂移前
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

-- B组近期（1-20天前，清淡系）→ 漂移后
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

-- C组曝光
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',FLOOR(1+RAND()*15),',',FLOOR(1+RAND()*15),',',FLOOR(1+RAND()*15),']'),
       'fused-pmfup-prmidm-ammbc-v3', '',
       DATE_SUB(@now, INTERVAL FLOOR(30+RAND()*90) DAY)
FROM user u WHERE u.openid LIKE 'grpC_%' AND u.current_flight_id IS NOT NULL
LIMIT 120;

-- C组手动选择（清真系，集中选择）
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

-- D组曝光（冷启动，极少日志）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',FLOOR(1+RAND()*15),',',FLOOR(1+RAND()*15),']'),
       'fused-pmfup-prmidm-ammbc-v3', '',
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*5) DAY)
FROM user u WHERE u.openid LIKE 'grpD_%' AND u.current_flight_id IS NOT NULL
LIMIT 20;

-- ============================================================
-- PHASE 7: meal_selection 记录
-- ============================================================

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT CONCAT('SEL',UNIX_TIMESTAMP(NOW()),u.id),
       3, u.id, u.current_flight_id, 1,
       CONCAT(FLOOR(1+RAND()*30), CHAR(65+FLOOR(RAND()*6))),
       DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*30) DAY), @now
FROM user u
WHERE (u.openid LIKE 'grpA_%' OR u.openid LIKE 'grpB_%' OR u.openid LIKE 'grpC_%')
  AND u.current_flight_id IS NOT NULL
LIMIT 150;

-- ============================================================
-- 验证查询（执行后检查）
-- ============================================================
-- SELECT COUNT(*) total_users FROM user;
-- SELECT COUNT(*) new_users FROM user WHERE openid LIKE 'grp%';
-- SELECT COUNT(*) total_dishes FROM dish WHERE status=1;
-- SELECT COUNT(*) total_logs FROM recommendation_log;
-- SELECT COUNT(*) manual_logs FROM recommendation_log WHERE user_feedback LIKE 'MANUAL_SELECTED%';
-- SELECT u.current_flight_id, COUNT(*) FROM user u WHERE u.openid LIKE 'grp%' GROUP BY u.current_flight_id;
