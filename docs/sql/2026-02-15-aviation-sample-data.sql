-- 航空旅客智能美食推荐系统：样本数据脚本（幂等）
-- 执行前请先执行：2026-02-15-aviation-mvp.sql

USE aviation_food_recommend;

SET @now = NOW();

-- 0-1) 确保关键表 id 主键可自增（若已是自增则跳过）
SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'category' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip category.id auto_increment"',
  'ALTER TABLE category MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip dish.id auto_increment"',
  'ALTER TABLE dish MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'flight_info' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip flight_info.id auto_increment"',
  'ALTER TABLE flight_info MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'flight_route_dish' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip flight_route_dish.id auto_increment"',
  'ALTER TABLE flight_route_dish MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user_preference' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip user_preference.id auto_increment"',
  'ALTER TABLE user_preference MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'recommendation_log' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip recommendation_log.id auto_increment"',
  'ALTER TABLE recommendation_log MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'flight_announcement' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip flight_announcement.id auto_increment"',
  'ALTER TABLE flight_announcement MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'meal_selection' AND column_name = 'id' AND extra LIKE '%auto_increment%'),
  'SELECT "skip meal_selection.id auto_increment"',
  'ALTER TABLE meal_selection MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 0) 确保 dish 推荐字段存在（若已存在则跳过）
SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'meal_type'
  ),
  'SELECT "skip dish.meal_type"',
  'ALTER TABLE dish ADD COLUMN meal_type TINYINT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'pic'
  ),
  'SELECT "skip dish.pic"',
  'ALTER TABLE dish ADD COLUMN pic LONGTEXT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'detail'
  ),
  'SELECT "skip dish.detail"',
  'ALTER TABLE dish ADD COLUMN detail VARCHAR(255) NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'flavor_tags'
  ),
  'SELECT "skip dish.flavor_tags"',
  'ALTER TABLE dish ADD COLUMN flavor_tags JSON NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1) 菜品分类样本（type=1）
INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '航旅主餐', 1, 1, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '航旅主餐');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '轻食健康', 1, 2, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '轻食健康');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '清真专区', 1, 3, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '清真专区');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '儿童餐食', 1, 4, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '儿童餐食');

SELECT id INTO @cat_main FROM category WHERE name = '航旅主餐' LIMIT 1;
SELECT id INTO @cat_light FROM category WHERE name = '轻食健康' LIMIT 1;
SELECT id INTO @cat_halal FROM category WHERE name = '清真专区' LIMIT 1;
SELECT id INTO @cat_child FROM category WHERE name = '儿童餐食' LIMIT 1;

-- 2) 餐食样本（含航空推荐字段）
INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '香煎鸡胸藜麦饭', '', '低脂高蛋白，适合长航程午餐', 1, @cat_light, 2, JSON_ARRAY('清淡', '低脂', '高蛋白'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '香煎鸡胸藜麦饭');

INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '西域清炖牛肉饭', '', '清真认证风味，软烂易消化', 1, @cat_halal, 3, JSON_ARRAY('清真', '咸香', '软烂'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '西域清炖牛肉饭');

INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '番茄意面儿童餐', '', '少盐少辣，含玉米胡萝卜', 1, @cat_child, 1, JSON_ARRAY('少盐', '不辣', '番茄'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '番茄意面儿童餐');

INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '全素菌菇烩饭', '', '纯素搭配，口感清爽', 1, @cat_light, 4, JSON_ARRAY('素食', '清淡', '菌菇'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '全素菌菇烩饭');

INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '经典红烧牛腩饭', '', '大众标准餐，咸鲜风味', 1, @cat_main, 2, JSON_ARRAY('咸鲜', '浓郁', '热食'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '经典红烧牛腩饭');

SELECT id INTO @dish_quinoa FROM dish WHERE name = '香煎鸡胸藜麦饭' LIMIT 1;
SELECT id INTO @dish_halal FROM dish WHERE name = '西域清炖牛肉饭' LIMIT 1;
SELECT id INTO @dish_child FROM dish WHERE name = '番茄意面儿童餐' LIMIT 1;
SELECT id INTO @dish_vegan FROM dish WHERE name = '全素菌菇烩饭' LIMIT 1;
SELECT id INTO @dish_beef FROM dish WHERE name = '经典红烧牛腩饭' LIMIT 1;

-- 3) 航班样本
INSERT INTO flight_info
(id, flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 1001, 'CZ3101', '广州', '北京', '2026-02-20 08:30:00', '2026-02-20 11:30:00', 180, 1, JSON_ARRAY('早餐'), '2026-02-19 20:30:00', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'CZ3101');

INSERT INTO flight_info
(id, flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 1002, 'MU5120', '上海', '成都', '2026-02-20 12:00:00', '2026-02-20 15:20:00', 200, 1, JSON_ARRAY('午餐'), '2026-02-20 09:00:00', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'MU5120');

INSERT INTO flight_info
(id, flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 1003, 'CA1888', '北京', '乌鲁木齐', '2026-02-21 14:10:00', '2026-02-21 18:25:00', 255, 2, JSON_ARRAY('午餐', '加餐'), '2026-02-21 10:10:00', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'CA1888');

SELECT id INTO @flight_cz3101 FROM flight_info WHERE flight_number = 'CZ3101' LIMIT 1;
SELECT id INTO @flight_mu5120 FROM flight_info WHERE flight_number = 'MU5120' LIMIT 1;
SELECT id INTO @flight_ca1888 FROM flight_info WHERE flight_number = 'CA1888' LIMIT 1;

-- 4) 航线餐食映射（用于推荐按航线筛选）
INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '广州', '北京', @dish_quinoa, 1, 1
WHERE @dish_quinoa IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure = '广州' AND destination = '北京' AND dish_id = @dish_quinoa
  );

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '广州', '北京', @dish_beef, 1, 2
WHERE @dish_beef IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure = '广州' AND destination = '北京' AND dish_id = @dish_beef
  );

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '上海', '成都', @dish_vegan, 1, 1
WHERE @dish_vegan IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure = '上海' AND destination = '成都' AND dish_id = @dish_vegan
  );

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '北京', '乌鲁木齐', @dish_halal, 1, 1
WHERE @dish_halal IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure = '北京' AND destination = '乌鲁木齐' AND dish_id = @dish_halal
  );

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '北京', '乌鲁木齐', @dish_child, 1, 2
WHERE @dish_child IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure = '北京' AND destination = '乌鲁木齐' AND dish_id = @dish_child
  );

-- 5) 航班公告样本
INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time)
SELECT @flight_cz3101, 'CZ3101 餐食预选开放', '本次航班已开放餐食预选，请于起飞前12小时完成选择。', 1, 1, @now, @now
WHERE @flight_cz3101 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_announcement WHERE title = 'CZ3101 餐食预选开放');

INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time)
SELECT @flight_ca1888, 'CA1888 清真餐保障提示', '清真餐将按预定数量保障供应，建议尽早完成偏好配置。', 1, 1, @now, @now
WHERE @flight_ca1888 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_announcement WHERE title = 'CA1888 清真餐保障提示');

-- 6) 用户偏好样本
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT 1, JSON_ARRAY(2,4), JSON_ARRAY('清淡','低脂'), JSON_ARRAY('花生'), '偏好清淡，避免坚果', @now, @now
WHERE NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = 1);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT 2, JSON_ARRAY(3), JSON_ARRAY('咸香'), JSON_ARRAY(), '仅选择清真餐', @now, @now
WHERE NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = 2);

-- 7) 推荐日志样本（用于看板统计）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT 1, @flight_cz3101, JSON_ARRAY('香煎鸡胸藜麦饭','全素菌菇烩饭'), 'hybrid-v1', 5, '匹配度高，口味合适', @now
WHERE @flight_cz3101 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM recommendation_log
    WHERE user_id = 1 AND flight_id = @flight_cz3101 AND algorithm_type = 'hybrid-v1'
  );

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT 2, @flight_ca1888, JSON_ARRAY('西域清炖牛肉饭'), 'hybrid-v1', 4, '清真选项可用，满意', @now
WHERE @flight_ca1888 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM recommendation_log
    WHERE user_id = 2 AND flight_id = @flight_ca1888 AND algorithm_type = 'hybrid-v1'
  );

-- 8) 餐食预选单样本（用于 dashboard 统计）
INSERT INTO meal_selection (number, status, user_id, flight_id, seat_number, create_time, update_time)
SELECT CONCAT('MS', DATE_FORMAT(@now, '%Y%m%d'), '001'), 1, 1, @flight_cz3101, '12A', @now, @now
WHERE @flight_cz3101 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM meal_selection WHERE user_id = 1 AND flight_id = @flight_cz3101 AND seat_number = '12A'
  );

INSERT INTO meal_selection (number, status, user_id, flight_id, seat_number, create_time, update_time)
SELECT CONCAT('MS', DATE_FORMAT(@now, '%Y%m%d'), '002'), 1, 2, @flight_ca1888, '18C', @now, @now
WHERE @flight_ca1888 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM meal_selection WHERE user_id = 2 AND flight_id = @flight_ca1888 AND seat_number = '18C'
  );
