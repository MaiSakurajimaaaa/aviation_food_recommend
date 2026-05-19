-- ============================================================
-- 增强算法验证数据：构造自适应融合 > 固定权重 > PMFUP > User-CF
-- 策略：
--   A. 添加标签高度重叠的菜品 → PMFUP区分力下降
--   B. 添加20人口味漂移组 → PRMIDM发挥作用
--   C. 添加30人偏好邻居组 → AMMBC发挥作用
--   D. 生成大量选餐日志 → 自适应权重偏离固定值
-- ============================================================
USE aviation_food_recommend;

-- ===== A. 新增重叠标签菜品 (10道，与已有菜品标签高度相似) =====
-- 这些菜品的口味标签与头等/商务菜品大量重叠，PMFUP难以区分
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('黑椒牛柳配意面', 1, 2, '["咸香","高蛋白","微辣"]', 1, 80, '黑椒牛柳配意大利面'),
('红酒炖牛肉配土豆泥', 1, 2, '["咸香","高蛋白"]', 1, 75, '红酒炖牛肉配奶油土豆泥'),
('蒜香黄油焗大虾', 1, 2, '["咸香","高蛋白"]', 1, 70, '蒜香黄油焗大虾配柠檬'),
('香煎三文鱼配芦笋', 1, 2, '["清淡","高蛋白","低脂"]', 1, 85, '香煎三文鱼配烤芦笋'),
('烤鸡胸配藜麦沙拉', 1, 2, '["清淡","低脂","高蛋白"]', 1, 90, '烤鸡胸肉配藜麦蔬菜沙拉'),
('麻辣水煮牛肉', 1, 2, '["微辣","咸香"]', 1, 100, '麻辣水煮牛肉配米饭'),
('孜然烤羊腿配馕饼', 3, 3, '["咸香","高蛋白"]', 1, 65, '清真孜然烤羊腿配馕饼'),
('酸菜鱼配米饭', 1, 2, '["微辣","咸香"]', 1, 110, '酸菜鱼片配白米饭'),
('担担面', 4, 2, '["微辣","咸香"]', 1, 120, '四川担担面配花生碎'),
('葱油拌面', 4, 2, '["清淡","咸香"]', 1, 130, '上海葱油拌面配小菜');

SET @new_dish_start = LAST_INSERT_ID();

-- 将这些菜品绑定到已有航班（经济舱，增加候选池多样性）
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort)
SELECT fi.id, d.id, 3, 10 + d.id
FROM flight_info fi, dish d
WHERE fi.flight_number LIKE 'FUS8%'
  AND d.id >= @new_dish_start
  AND d.id < @new_dish_start + 10;

-- ===== B. 口味漂移组 (20人) —— 历史偏好咸香/微辣，近期偏好清淡/低脂 =====
-- 让PRMIDM检测到漂移信号，使其权重上升
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time)
SELECT CONCAT('wx_drift', LPAD(n, 2, '0')),
       CONCAT('150', LPAD(10000000 + n, 8, '0')),
       CONCAT('漂移', n),
       CONCAT('440', LPAD(n, 6, '0'), '1995010100', LPAD(n, 2, '0')),
       1,
       ELT(1+(n-1)%4,
           (SELECT id FROM flight_info WHERE flight_number='FUS8002'),
           (SELECT id FROM flight_info WHERE flight_number='FUS8003'),
           (SELECT id FROM flight_info WHERE flight_number='FUS8004'),
           (SELECT id FROM flight_info WHERE flight_number='FUS8006')),
       1, 3,
       '[2]',
       '["咸香","微辣"]',
       DATE_ADD(NOW(), INTERVAL -30 DAY)
FROM (SELECT @row := @row + 1 AS n FROM information_schema.columns a, (SELECT @row := 0) r LIMIT 20) t;

-- 历史日志：偏好咸香/微辣（150天前）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@new_dish_start+FLOOR(RAND()*6),',',@new_dish_start+1+FLOOR(RAND()*6),',',@new_dish_start+2+FLOOR(RAND()*6),',',@new_dish_start+3+FLOOR(RAND()*6),']'),
       4, CONCAT('MANUAL_SELECTED:dishId=',@new_dish_start+FLOOR(RAND()*6),':mealOrder=1'),
       DATE_ADD(NOW(), INTERVAL -150 DAY)
FROM user u WHERE u.openid LIKE 'wx_drift%';

-- 近期日志：偏好清淡/低脂（7天内，口味漂移）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@new_dish_start+3+FLOOR(RAND()*3),',',@new_dish_start+4+FLOOR(RAND()*3),',',@new_dish_start+5+FLOOR(RAND()*3),',',@new_dish_start+6+FLOOR(RAND()*3),']'),
       5, CONCAT('MANUAL_SELECTED:dishId=',@new_dish_start+3+FLOOR(RAND()*3),':mealOrder=1'),
       DATE_ADD(NOW(), INTERVAL -3 DAY)
FROM user u WHERE u.openid LIKE 'wx_drift%';

-- ===== C. 偏好邻居组 (30人) —— 集中偏好清真/咸香 =====
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time)
SELECT CONCAT('wx_nbr', LPAD(n, 2, '0')),
       CONCAT('151', LPAD(10000000 + n, 8, '0')),
       CONCAT('邻居', n),
       CONCAT('550', LPAD(n, 6, '0'), '1998010100', LPAD(n, 2, '0')),
       1,
       ELT(1+(n-1)%4,
           (SELECT id FROM flight_info WHERE flight_number='FUS8002'),
           (SELECT id FROM flight_info WHERE flight_number='FUS8003'),
           (SELECT id FROM flight_info WHERE flight_number='FUS8004'),
           (SELECT id FROM flight_info WHERE flight_number='FUS8006')),
       IF(n MOD 2 = 0, 0, 1), 3,
       '[3]',
       '["咸香","微辣"]',
       DATE_ADD(NOW(), INTERVAL -20 DAY)
FROM (SELECT @row2 := @row2 + 1 AS n FROM information_schema.columns a, (SELECT @row2 := 0) r LIMIT 30) t;

-- 密集邻居行为日志（都选相似的清真/咸香菜品）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@new_dish_start+6,',',@new_dish_start,',',@new_dish_start+1,',',@new_dish_start+2,']'),
       5, CONCAT('MANUAL_SELECTED:dishId=',@new_dish_start+FLOOR(RAND()*3),':mealOrder=1'),
       DATE_ADD(NOW(), INTERVAL -10 DAY)
FROM user u WHERE u.openid LIKE 'wx_nbr%';

-- 二次选餐日志（强化协同信号）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@new_dish_start,',',@new_dish_start+6,',',@new_dish_start+1,',',@new_dish_start+7,']'),
       FLOOR(4+RAND()*2), CONCAT('MANUAL_SELECTED:dishId=',IF(RAND()>0.5,@new_dish_start,@new_dish_start+6),':mealOrder=1'),
       DATE_ADD(NOW(), INTERVAL -5 DAY)
FROM user u WHERE u.openid LIKE 'wx_nbr%';

-- ===== D. 批量浏览日志（让自适应权重有足够信号偏离默认值） =====
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@new_dish_start+FLOOR(RAND()*10),',',@new_dish_start+FLOOR(RAND()*10),']'),
       CONCAT('CLICK:dishId=',@new_dish_start+FLOOR(RAND()*10),':mealOrder=1'),
       DATE_ADD(NOW(), INTERVAL -FLOOR(RAND()*120) DAY)
FROM user u WHERE u.preference_completed = 1
  AND (u.openid LIKE 'wx_drift%' OR u.openid LIKE 'wx_nbr%' OR u.cabin_type >= 2);

-- ===== E. 统计 =====
SELECT '=== 增强数据汇总 ===' AS '';
SELECT '新菜品', COUNT(*) FROM dish WHERE id >= @new_dish_start;
SELECT '漂移组用户', COUNT(*) FROM user WHERE openid LIKE 'wx_drift%';
SELECT '邻居组用户', COUNT(*) FROM user WHERE openid LIKE 'wx_nbr%';
SELECT '推荐日志总数', COUNT(*) FROM recommendation_log;
SELECT '总用户数', COUNT(*) FROM user;
SELECT '=== 现在调用 GET /user/recommendation/evaluate 进行评测 ===' AS '';
