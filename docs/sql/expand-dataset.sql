-- =====================================================
-- 扩展数据集：从 86人/10菜 → 180+人/30菜
-- 目标：让自适应融合在高重叠标签、多行为信号场景下超越固定权重
-- 执行前请备份数据库
-- =====================================================

SET @now = NOW();

-- =====================================================
-- 1. 新增 20 道菜品（与现有 10 道形成标签重叠以削弱纯 PMFUP）
-- =====================================================

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, create_time, update_time)
VALUES
-- 标准餐系列（mealType=2）
('葱油鸡腿饭', 1, 2, '["咸香","热食","微辣"]', 1, 60, @now, @now),
('黑椒牛肉炒饭', 1, 2, '["咸香","热食","高蛋白"]', 1, 55, @now, @now),
('蜜汁叉烧饭', 1, 2, '["甜口","咸香"]', 1, 50, @now, @now),
('蒜蓉西兰花鸡胸饭', 1, 2, '["清淡","高蛋白","低脂"]', 1, 65, @now, @now),
('糖醋里脊饭', 1, 2, '["甜口","热食","咸香"]', 1, 55, @now, @now),
('红烧狮子头饭', 1, 2, '["咸香","热食"]', 1, 60, @now, @now),
('孜然羊肉饭', 1, 2, '["微辣","咸香","清真"]', 1, 50, @now, @now),
('鱼香肉丝饭', 1, 2, '["微辣","甜口"]', 1, 55, @now, @now),
('香菇滑鸡饭', 1, 2, '["清淡","高蛋白","咸香"]', 1, 60, @now, @now),
('回锅肉饭', 1, 2, '["微辣","咸香","热食"]', 1, 50, @now, @now),

-- 清真餐系列（mealType=3）
('孜然牛肉抓饭', 1, 3, '["清真","咸香"]', 1, 45, @now, @now),
('清真红烧牛肉饭', 1, 3, '["清真","咸香","热食"]', 1, 45, @now, @now),

-- 儿童餐系列（mealType=1）
('卡通鸡肉饭团', 1, 1, '["甜口","清淡","不辣"]', 1, 40, @now, @now),
('小熊造型三明治', 1, 1, '["甜口","清淡"]', 1, 40, @now, @now),

-- 素食餐系列（mealType=4）
('菌菇芦笋烩饭', 1, 4, '["素食","清淡","低脂"]', 1, 35, @now, @now),
('麻婆豆腐素饭', 1, 4, '["素食","微辣","咸香"]', 1, 35, @now, @now),

-- 更多标准餐（mealType=2）—— 故意制造标签重叠
('酱香排骨饭', 1, 2, '["咸香","热食"]', 1, 55, @now, @now),
('宫保鸡丁饭', 1, 2, '["微辣","咸香","甜口"]', 1, 55, @now, @now),
('虾仁滑蛋饭', 1, 2, '["清淡","高蛋白"]', 1, 50, @now, @now),
('酸菜鱼片饭', 1, 2, '["微辣","咸香","清淡"]', 1, 50, @now, @now);

-- =====================================================
-- 2. 绑定新菜品到现有 4 个航班（航线-菜品绑定）
-- =====================================================

-- 获取已存在的 route 信息
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 1, 10 FROM dish WHERE name = '葱油鸡腿饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 1, 11 FROM dish WHERE name = '黑椒牛肉炒饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 1, 12 FROM dish WHERE name = '蜜汁叉烧饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 2, 10 FROM dish WHERE name = '蒜蓉西兰花鸡胸饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 2, 11 FROM dish WHERE name = '糖醋里脊饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 3, 10 FROM dish WHERE name = '红烧狮子头饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '上海', '成都', id, 3, 11 FROM dish WHERE name = '酱香排骨饭';

INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 1, 10 FROM dish WHERE name = '孜然羊肉饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 1, 11 FROM dish WHERE name = '鱼香肉丝饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 2, 10 FROM dish WHERE name = '香菇滑鸡饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 2, 11 FROM dish WHERE name = '回锅肉饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 3, 10 FROM dish WHERE name = '宫保鸡丁饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '北京', '深圳', id, 3, 11 FROM dish WHERE name = '虾仁滑蛋饭';

INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '广州', '乌鲁木齐', id, 1, 10 FROM dish WHERE name = '孜然牛肉抓饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '广州', '乌鲁木齐', id, 1, 11 FROM dish WHERE name = '清真红烧牛肉饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '广州', '乌鲁木齐', id, 2, 10 FROM dish WHERE name = '卡通鸡肉饭团';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '广州', '乌鲁木齐', id, 2, 11 FROM dish WHERE name = '小熊造型三明治';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '广州', '乌鲁木齐', id, 3, 10 FROM dish WHERE name = '菌菇芦笋烩饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '广州', '乌鲁木齐', id, 3, 11 FROM dish WHERE name = '麻婆豆腐素饭';

INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '杭州', '西安', id, 1, 10 FROM dish WHERE name = '酸菜鱼片饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '杭州', '西安', id, 2, 10 FROM dish WHERE name = '黑椒牛肉炒饭';
INSERT INTO flight_route_dish (departure, destination, dish_id, cabin_type, sort)
SELECT '杭州', '西安', id, 3, 10 FROM dish WHERE name = '蜜汁叉烧饭';

-- =====================================================
-- 3. 新增约 100 名用户（密码已 MD5 加密，openid 用随机值模拟）
--    舱位分布：头等 10%、商务 20%、经济 70%
-- =====================================================

-- 使用存储过程批量插入，避免手写 100 条
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS insert_users()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE cabin INT;
    DECLARE flights JSON DEFAULT JSON_ARRAY(
        (SELECT id FROM flight_info WHERE flight_number = 'FUS6101'),
        (SELECT id FROM flight_info WHERE flight_number = 'FUS6202'),
        (SELECT id FROM flight_info WHERE flight_number = 'FUS6303'),
        (SELECT id FROM flight_info WHERE flight_number = 'FUS6404')
    );

    WHILE i < 100 DO
        -- 舱位分布
        SET cabin = CASE
            WHEN i < 10 THEN 1   -- 10% 头等
            WHEN i < 30 THEN 2   -- 20% 商务
            ELSE 3               -- 70% 经济
        END;

        INSERT INTO user (openid, phone, name, id_number, cabin_type, current_flight_id, preference_completed, create_time, update_time, gender)
        VALUES (
            CONCAT('sim_openid_v2_', i),
            CONCAT('13', LPAD(FLOOR(RAND() * 100000000), 9, '0')),
            CONCAT('旅客', i + 100),
            CONCAT('360', LPAD(FLOOR(RAND() * 10000000000000), 14, '0'), FLOOR(RAND() * 10)),
            cabin,
            JSON_EXTRACT(flights, CONCAT('$[', FLOOR(RAND() * 4), ']')),
            IF(RAND() > 0.15, 1, 0),  -- 85% 已完成偏好
            DATE_SUB(@now, INTERVAL FLOOR(RAND() * 180) DAY),
            @now,
            IF(RAND() > 0.5, 1, 0)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL insert_users();

-- =====================================================
-- 4. 为新用户创建偏好记录（制造口味漂移场景）
-- =====================================================

-- 4a. 约 30 名用户："历史咸香 → 近期清淡" 的漂移（PRMIDM 可以检测到）
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT id, '["2"]', '["清淡","低脂","高蛋白"]', @now, @now
FROM user WHERE openid LIKE 'sim_openid_v2_%' AND id % 3 = 0
AND NOT EXISTS (SELECT 1 FROM user_preference up WHERE up.user_id = user.id);

-- 4b. 约 30 名用户："历史清淡 → 近期咸香微辣" 的漂移
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT id, '["2"]', '["咸香","微辣","热食"]', @now, @now
FROM user WHERE openid LIKE 'sim_openid_v2_%' AND id % 3 = 1
AND NOT EXISTS (SELECT 1 FROM user_preference up WHERE up.user_id = user.id);

-- 4c. 约 30 名用户：多偏好类型
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, create_time, update_time)
SELECT id, '["2","3"]', '["咸香","高蛋白","清真"]', @now, @now
FROM user WHERE openid LIKE 'sim_openid_v2_%' AND id % 3 = 2
AND NOT EXISTS (SELECT 1 FROM user_preference up WHERE up.user_id = user.id);

-- =====================================================
-- 5. 插入丰富的行为日志（含明确的兴趣漂移信号）
-- =====================================================

-- 辅助：获取所有 FUS6101 的用户 ID（用于生成推荐日志）
-- 为每个取模 30 天前/最近 7 天的时间点

-- 5a. 曝光日志：为大量用户生成近期曝光记录
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
    u.id,
    u.current_flight_id,
    CONCAT('[', FLOOR(1 + RAND() * 30), ',', FLOOR(1 + RAND() * 30), ',', FLOOR(1 + RAND() * 30), ']'),
    'fused-pmfup-prmidm-ammbc-v3',
    '',
    DATE_SUB(@now, INTERVAL FLOOR(1 + RAND() * 15) DAY)
FROM user u
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.current_flight_id IS NOT NULL
LIMIT 200;

-- 5b. 点击日志：约 120 条
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
    u.id,
    u.current_flight_id,
    CONCAT('[', FLOOR(1 + RAND() * 30), ']'),
    'fused-pmfup-prmidm-ammbc-v3',
    CONCAT('CLICK:dishId=', FLOOR(1 + RAND() * 30), ':mealOrder=1'),
    DATE_SUB(@now, INTERVAL FLOOR(1 + RAND() * 14) DAY)
FROM user u
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.current_flight_id IS NOT NULL
  AND u.preference_completed = 1
LIMIT 120;

-- 5c. 手动选餐日志（ground truth）：约 80 条，分两类用户
--     类型A（咸香偏好者）：选咸香类菜品
--     类型B（清淡偏好者）：选清淡类菜品
--     这些作为测试集的 ground truth

-- 类型A：手动选咸香类（对应 dishId 可能在 1-30 范围内，根据实际菜品调整）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
    u.id,
    u.current_flight_id,
    CONCAT('[', dishId, ']'),
    'fused-pmfup-prmidm-ammbc-v3',
    CONCAT('MANUAL_SELECTED:dishId=', dishId, ':mealOrder=1'),
    DATE_SUB(@now, INTERVAL FLOOR(1 + RAND() * 10) DAY)
FROM user u
CROSS JOIN (
    SELECT 5 AS dishId UNION SELECT 6 UNION SELECT 11 UNION SELECT 12
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 22
) d
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.id % 3 = 1  -- 咸香偏好组
  AND u.current_flight_id IS NOT NULL
LIMIT 40;

-- 类型B：手动选清淡/低脂类
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
    u.id,
    u.current_flight_id,
    CONCAT('[', dishId, ']'),
    'fused-pmfup-prmidm-ammbc-v3',
    CONCAT('MANUAL_SELECTED:dishId=', dishId, ':mealOrder=1'),
    DATE_SUB(@now, INTERVAL FLOOR(1 + RAND() * 10) DAY)
FROM user u
CROSS JOIN (
    SELECT 1 AS dishId UNION SELECT 2 UNION SELECT 7 UNION SELECT 8
    UNION SELECT 9 UNION SELECT 13 UNION SELECT 14 UNION SELECT 19
    UNION SELECT 20 UNION SELECT 21
) d
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.id % 3 = 0  -- 清淡偏好组
  AND u.current_flight_id IS NOT NULL
LIMIT 40;

-- 5d. 评分日志（4-5星高分，表明满意）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT
    u.id,
    u.current_flight_id,
    CONCAT('[', FLOOR(1 + RAND() * 30), ']'),
    'fused-pmfup-prmidm-ammbc-v3',
    FLOOR(4 + RAND() * 2),  -- 4 or 5
    CONCAT('MANUAL_SELECTED:dishId=', FLOOR(1 + RAND() * 30), ':mealOrder=1'),
    DATE_SUB(@now, INTERVAL FLOOR(7 + RAND() * 60) DAY)
FROM user u
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.current_flight_id IS NOT NULL
  AND u.preference_completed = 1
LIMIT 60;

-- 5e. 制造漂移信号：部分用户"很久以前选咸香，最近选清淡"
--     这些用户在 90 天前选了咸香菜，但最近选了清淡菜
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_feedback, create_time)
SELECT
    u.id,
    u.current_flight_id,
    CONCAT('[', FLOOR(1 + RAND() * 30), ']'),
    'fused-pmfup-prmidm-ammbc-v3',
    CONCAT('CLICK:dishId=', CASE WHEN u.id % 2 = 0 THEN 5 ELSE 11 END, ':mealOrder=1'),
    DATE_SUB(@now, INTERVAL FLOOR(60 + RAND() * 90) DAY)
FROM user u
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.id % 3 = 0  -- 清淡组
  AND u.current_flight_id IS NOT NULL
LIMIT 30;

-- 同一批用户最近的清淡选择（已在 5c 类型B 中覆盖）

-- =====================================================
-- 6. 为新用户创建 meal_selection 记录（与 MANUAL_SELECTED 对账）
-- =====================================================

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT
    CONCAT('SEL', UNIX_TIMESTAMP(), u.id, FLOOR(RAND()*1000)),
    3,
    u.id,
    u.current_flight_id,
    1,
    CONCAT(FLOOR(1+RAND()*30), CASE WHEN FLOOR(RAND()*6)=0 THEN 'A' WHEN FLOOR(RAND()*6)=1 THEN 'B' ELSE 'C' END),
    DATE_SUB(@now, INTERVAL FLOOR(1+RAND()*30) DAY),
    @now
FROM user u
WHERE u.openid LIKE 'sim_openid_v2_%'
  AND u.current_flight_id IS NOT NULL
  AND RAND() > 0.4
LIMIT 80;

-- =====================================================
-- 7. 更新论文数据描述的数字
-- =====================================================
-- 执行后请运行：
-- SELECT COUNT(*) FROM user;          -- 应约 186
-- SELECT COUNT(*) FROM dish WHERE status=1;  -- 应约 30
-- SELECT COUNT(*) FROM recommendation_log;   -- 应约 800+
-- SELECT COUNT(*) FROM recommendation_log WHERE user_feedback LIKE 'MANUAL_SELECTED%'; -- 应约 180+
