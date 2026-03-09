-- 目的：为 uniapp 用户端（微信登录 + 身份证核验 + 航班餐食预选）准备联调测试数据
-- 使用说明：
-- 1) 先确保执行过：2026-02-15-aviation-mvp.sql、2026-02-19-user-schema-compat.sql
-- 2) 最好先在小程序微信登录一次，让当前微信用户写入 user 表
-- 3) 再执行本脚本，将“最近登录用户”直接绑定测试身份证与航班

USE aviation_food_recommend;

SET @now = NOW();

-- A. 兜底：关键字段缺失时补齐（幂等）
SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'id_number'),
  'SELECT "skip add user.id_number"',
  'ALTER TABLE user ADD COLUMN id_number VARCHAR(18) NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'current_flight_id'),
  'SELECT "skip add user.current_flight_id"',
  'ALTER TABLE user ADD COLUMN current_flight_id BIGINT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'preference_completed'),
  'SELECT "skip add user.preference_completed"',
  'ALTER TABLE user ADD COLUMN preference_completed TINYINT DEFAULT 0'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- B. 基础分类与菜品（幂等）
INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '航旅主餐', 1, 1, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '航旅主餐');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '轻食健康', 1, 2, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '轻食健康');

SELECT id INTO @cat_main FROM category WHERE name = '航旅主餐' LIMIT 1;
SELECT id INTO @cat_light FROM category WHERE name = '轻食健康' LIMIT 1;

INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '经典红烧牛腩饭', '', '大众标准餐，咸鲜热食', 1, @cat_main, 2, JSON_ARRAY('咸鲜','热食'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '经典红烧牛腩饭');

INSERT INTO dish (name, pic, detail, status, category_id, meal_type, flavor_tags, create_user, update_user, create_time, update_time)
SELECT '香煎鸡胸藜麦饭', '', '低脂高蛋白，适合航旅预选', 1, @cat_light, 2, JSON_ARRAY('清淡','低脂','高蛋白'), 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '香煎鸡胸藜麦饭');

SELECT id INTO @dish_beef FROM dish WHERE name = '经典红烧牛腩饭' LIMIT 1;
SELECT id INTO @dish_quinoa FROM dish WHERE name = '香煎鸡胸藜麦饭' LIMIT 1;

-- C. 航班数据（幂等）
INSERT INTO flight_info
(id, flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 2001, 'MU2001', '上海', '成都', '2026-02-22 11:00:00', '2026-02-22 14:10:00', 190, 1, JSON_ARRAY('午餐'), '2026-02-22 08:00:00', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'MU2001');

INSERT INTO flight_info
(id, flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 2002, 'CZ2002', '广州', '北京', '2026-02-22 09:00:00', '2026-02-22 12:00:00', 180, 1, JSON_ARRAY('早餐'), '2026-02-22 06:00:00', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'CZ2002');

SELECT id INTO @flight_main FROM flight_info WHERE flight_number = 'MU2001' LIMIT 1;
SELECT id INTO @flight_alt FROM flight_info WHERE flight_number = 'CZ2002' LIMIT 1;

-- D. 航线餐食映射（幂等）
INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '上海', '成都', @dish_beef, 1, 1
WHERE @dish_beef IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure='上海' AND destination='成都' AND dish_id=@dish_beef
  );

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, sort)
SELECT '上海', '成都', @dish_quinoa, 1, 2
WHERE @dish_quinoa IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM flight_route_dish
    WHERE departure='上海' AND destination='成都' AND dish_id=@dish_quinoa
  );

-- E. 航班公告（幂等）
INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time)
SELECT @flight_main, 'MU2001 餐食预选已开放', '请于起飞前3小时完成餐食预选。', 1, 1, @now, @now
WHERE @flight_main IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_announcement WHERE title='MU2001 餐食预选已开放');

-- F. 将“最近登录的微信用户”设置为可测试账号（身份证核验 + 已绑定航班）
-- 说明：当前小程序流程按 token 对应 user.id 查询，因此这里绑定 MAX(id) 通常就是你刚登录的微信用户
SELECT MAX(id) INTO @current_user_id FROM user;

-- 若还没有用户（极少情况），创建一个兜底用户
INSERT INTO user (name, openid, phone, gender, id_number, pic, preference_completed, current_flight_id, create_time)
SELECT '测试旅客A', CONCAT('debug-openid-', DATE_FORMAT(@now, '%Y%m%d%H%i%s')), '13800138000', 1, '110101199001011234', '', 1, @flight_main, @now
WHERE @current_user_id IS NULL;

SELECT COALESCE(@current_user_id, LAST_INSERT_ID()) INTO @bind_user_id;

UPDATE user
SET name = COALESCE(NULLIF(name, ''), '测试旅客A'),
    phone = COALESCE(phone, '13800138000'),
    gender = COALESCE(gender, 1),
    id_number = '110101199001011234',
    current_flight_id = @flight_main,
    preference_completed = 1
WHERE id = @bind_user_id;

-- G. 给当前测试用户写偏好（幂等）
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @bind_user_id, JSON_ARRAY(2), JSON_ARRAY('清淡'), JSON_ARRAY('花生'), '偏好清淡，避免花生', @now, @now
WHERE NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @bind_user_id);

UPDATE user_preference
SET meal_type_preferences = JSON_ARRAY(2),
    flavor_preferences = JSON_ARRAY('清淡'),
    allergens = JSON_ARRAY('花生'),
    dietary_notes = '偏好清淡，避免花生',
    update_time = @now
WHERE user_id = @bind_user_id;

-- H. 额外插入一个“未绑定航班”用户，方便测试提示分支（非当前登录用户）
INSERT INTO user (name, openid, phone, gender, id_number, pic, preference_completed, current_flight_id, create_time)
SELECT '测试旅客B-未绑定', CONCAT('debug-unbound-', DATE_FORMAT(@now, '%Y%m%d%H%i%s')), '13900139000', 0, '110101199202022222', '', 0, NULL, @now
WHERE NOT EXISTS (
  SELECT 1 FROM user WHERE id_number = '110101199202022222'
);

-- I. 输出联调关键信息
SELECT id, name, openid, id_number, current_flight_id, preference_completed
FROM user
WHERE id = @bind_user_id;

SELECT id, flight_number, departure, destination, selection_deadline, status
FROM flight_info
WHERE id = @flight_main;

SELECT user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes
FROM user_preference
WHERE user_id = @bind_user_id;
