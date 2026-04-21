-- 目的：生成“系统功能 + 多元融合推荐算法”演示数据（幂等）
-- 适用：MySQL 5.7 / 8.0
-- 说明：
-- 1) 请先确保已执行基线建表脚本（docs/sql/sql.sql）
-- 2) 本脚本不会清空全库，只会补充/更新带有 demo 标识的数据

USE aviation_food_recommend;

-- 统一会话字符集与排序规则，避免 Windows/MySQL8 下的 collation 冲突
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
SET collation_connection = 'utf8mb4_general_ci';

SET @now = NOW();
SET @alg := 'fused-pmfup-prmidm-ammbc-v1';

-- A) 兼容性兜底：关键字段与闭环表
SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'cabin_type'),
  'SELECT "skip add user.cabin_type"',
  'ALTER TABLE user ADD COLUMN cabin_type TINYINT NOT NULL DEFAULT 3 COMMENT ''舱位类型:1头等舱,2商务舱,3经济舱'''
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'flight_route_dish' AND column_name = 'cabin_type'),
  'SELECT "skip add flight_route_dish.cabin_type"',
  'ALTER TABLE flight_route_dish ADD COLUMN cabin_type TINYINT NOT NULL DEFAULT 3 COMMENT ''舱位类型:1头等舱,2商务舱,3经济舱'''
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'meal_selection' AND column_name = 'meal_order'),
  'SELECT "skip add meal_selection.meal_order"',
  'ALTER TABLE meal_selection ADD COLUMN meal_order TINYINT NOT NULL DEFAULT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS flight_service_rating (
  id               BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id          BIGINT NOT NULL,
  flight_id        BIGINT NOT NULL,
  source_log_id    BIGINT NULL,
  rating_score     TINYINT NULL,
  rating_status    VARCHAR(16) NOT NULL DEFAULT 'PENDING',
  first_visible_at DATETIME NULL,
  last_visible_at  DATETIME NULL,
  next_remind_at   DATETIME NULL,
  defer_count      INT NOT NULL DEFAULT 0,
  submitted_at     DATETIME NULL,
  expire_at        DATETIME NULL,
  channel          VARCHAR(16) NULL DEFAULT 'miniapp',
  create_time      DATETIME NULL,
  update_time      DATETIME NULL,
  UNIQUE KEY uk_rating_user_flight (user_id, flight_id),
  KEY idx_rating_pending (user_id, rating_status, next_remind_at, expire_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- B) 管理端登录账号（密码明文 123456，对应 MD5）
INSERT INTO employee (name, account, password, phone, age, gender, pic, status, create_user, update_user, create_time, update_time)
SELECT '推荐演示管理员', 'admin_demo', 'e10adc3949ba59abbe56e057f20f883e', '13800000000', 28, 1, '', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE account = 'admin_demo');
INSERT INTO employee (name, account, password, phone, age, gender, pic, status, create_user, update_user, create_time, update_time)
SELECT '推荐演示管理员', 'admin', 'e10adc3949ba59abbe56e057f20f883e', '13800000000', 28, 1, '', 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE account = 'admin');
-- C) 菜品分类
INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '融合主餐', 1, 1, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '融合主餐');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '轻食健康', 1, 2, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '轻食健康');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '清真专区', 1, 3, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '清真专区');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '早餐系列', 1, 4, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '早餐系列');

INSERT INTO category (name, type, sort, status, create_user, update_user, create_time, update_time)
SELECT '儿童餐食', 1, 5, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = '儿童餐食');

SELECT id INTO @cat_main FROM category WHERE name = '融合主餐' LIMIT 1;
SELECT id INTO @cat_light FROM category WHERE name = '轻食健康' LIMIT 1;
SELECT id INTO @cat_halal FROM category WHERE name = '清真专区' LIMIT 1;
SELECT id INTO @cat_breakfast FROM category WHERE name = '早餐系列' LIMIT 1;
SELECT id INTO @cat_child FROM category WHERE name = '儿童餐食' LIMIT 1;

-- D) 菜品（覆盖 meal_type、flavor_tags、stock）
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '低脂鸡胸藜麦饭', @cat_light, 2, JSON_ARRAY('清淡','低脂','高蛋白'), 1, 80, '', '低脂高蛋白主餐，适配健康偏好', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '低脂鸡胸藜麦饭');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '经典红烧牛腩饭', @cat_main, 2, JSON_ARRAY('咸香','热食'), 1, 90, '', '经典大众热食，适合午晚餐', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '经典红烧牛腩饭');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '香烤鳕鱼时蔬饭', @cat_light, 2, JSON_ARRAY('清淡','高蛋白'), 1, 70, '', '高蛋白清淡口感，适合长航程', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '香烤鳕鱼时蔬饭');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '川香麻辣牛肉面', @cat_main, 2, JSON_ARRAY('微辣','咸香'), 1, 65, '', '偏辣高满足主食', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '川香麻辣牛肉面');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '清真咖喱鸡肉饭', @cat_halal, 3, JSON_ARRAY('清真','咸香'), 1, 60, '', '清真可选，风味稳定', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '清真咖喱鸡肉饭');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '能量火腿三明治', @cat_breakfast, 2, JSON_ARRAY('清淡','高蛋白'), 1, 75, '', '早餐时段优先加权菜品', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '能量火腿三明治');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '豆浆油条组合', @cat_breakfast, 2, JSON_ARRAY('咸香','热食'), 1, 70, '', '典型早餐关键词菜品', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '豆浆油条组合');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '番茄儿童意面', @cat_child, 1, JSON_ARRAY('甜口','不辣'), 1, 55, '', '儿童友好口味', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '番茄儿童意面');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '全素菌菇烩饭', @cat_light, 4, JSON_ARRAY('清淡','低脂','素食'), 1, 50, '', '素食需求可选', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '全素菌菇烩饭');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_user, update_user, create_time, update_time)
SELECT '低脂水果酸奶杯', @cat_light, 4, JSON_ARRAY('甜口','清淡','低脂'), 1, 80, '', '轻食加餐，用于多元偏好融合', 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM dish WHERE name = '低脂水果酸奶杯');

SELECT id INTO @dish_lowfat FROM dish WHERE name = '低脂鸡胸藜麦饭' LIMIT 1;
SELECT id INTO @dish_beef FROM dish WHERE name = '经典红烧牛腩饭' LIMIT 1;
SELECT id INTO @dish_fish FROM dish WHERE name = '香烤鳕鱼时蔬饭' LIMIT 1;
SELECT id INTO @dish_spicy FROM dish WHERE name = '川香麻辣牛肉面' LIMIT 1;
SELECT id INTO @dish_halal FROM dish WHERE name = '清真咖喱鸡肉饭' LIMIT 1;
SELECT id INTO @dish_breakfast1 FROM dish WHERE name = '能量火腿三明治' LIMIT 1;
SELECT id INTO @dish_breakfast2 FROM dish WHERE name = '豆浆油条组合' LIMIT 1;
SELECT id INTO @dish_child FROM dish WHERE name = '番茄儿童意面' LIMIT 1;
SELECT id INTO @dish_vegan FROM dish WHERE name = '全素菌菇烩饭' LIMIT 1;
SELECT id INTO @dish_yogurt FROM dish WHERE name = '低脂水果酸奶杯' LIMIT 1;

-- 每次执行都回填分类与餐型映射，避免“早餐系列+儿童餐型”这类展示冗余
UPDATE dish
SET category_id=@cat_light, meal_type=2, flavor_tags=JSON_ARRAY('清淡','低脂','高蛋白'), status=1, stock=GREATEST(IFNULL(stock,0), 80), update_user=1, update_time=@now
WHERE name='低脂鸡胸藜麦饭';

UPDATE dish
SET category_id=@cat_main, meal_type=2, flavor_tags=JSON_ARRAY('咸香','热食'), status=1, stock=GREATEST(IFNULL(stock,0), 90), update_user=1, update_time=@now
WHERE name='经典红烧牛腩饭';

UPDATE dish
SET category_id=@cat_light, meal_type=2, flavor_tags=JSON_ARRAY('清淡','高蛋白'), status=1, stock=GREATEST(IFNULL(stock,0), 70), update_user=1, update_time=@now
WHERE name='香烤鳕鱼时蔬饭';

UPDATE dish
SET category_id=@cat_main, meal_type=2, flavor_tags=JSON_ARRAY('微辣','咸香'), status=1, stock=GREATEST(IFNULL(stock,0), 65), update_user=1, update_time=@now
WHERE name='川香麻辣牛肉面';

UPDATE dish
SET category_id=@cat_halal, meal_type=3, flavor_tags=JSON_ARRAY('清真','咸香'), status=1, stock=GREATEST(IFNULL(stock,0), 60), update_user=1, update_time=@now
WHERE name='清真咖喱鸡肉饭';

UPDATE dish
SET category_id=@cat_breakfast, meal_type=2, flavor_tags=JSON_ARRAY('清淡','高蛋白'), status=1, stock=GREATEST(IFNULL(stock,0), 75), update_user=1, update_time=@now
WHERE name='能量火腿三明治';

UPDATE dish
SET category_id=@cat_breakfast, meal_type=2, flavor_tags=JSON_ARRAY('咸香','热食'), status=1, stock=GREATEST(IFNULL(stock,0), 70), update_user=1, update_time=@now
WHERE name='豆浆油条组合';

UPDATE dish
SET category_id=@cat_child, meal_type=1, flavor_tags=JSON_ARRAY('甜口','不辣'), status=1, stock=GREATEST(IFNULL(stock,0), 55), update_user=1, update_time=@now
WHERE name='番茄儿童意面';

UPDATE dish
SET category_id=@cat_light, meal_type=4, flavor_tags=JSON_ARRAY('清淡','低脂','素食'), status=1, stock=GREATEST(IFNULL(stock,0), 50), update_user=1, update_time=@now
WHERE name='全素菌菇烩饭';

UPDATE dish
SET category_id=@cat_light, meal_type=4, flavor_tags=JSON_ARRAY('甜口','清淡','低脂'), status=1, stock=GREATEST(IFNULL(stock,0), 80), update_user=1, update_time=@now
WHERE name='低脂水果酸奶杯';

-- E) 航班（包含：可预选、已逾期未起飞、已到达近航班、已到达历史航班）
SET @f_active_departure := TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 1 DAY), '12:30:00');
SET @f_active_arrival := TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 1 DAY), '15:40:00');
SET @f_active_deadline := DATE_SUB(@f_active_departure, INTERVAL 4 HOUR);

SET @f_overdue_departure := DATE_ADD(@now, INTERVAL 4 HOUR);
SET @f_overdue_arrival := DATE_ADD(@now, INTERVAL 7 HOUR);
SET @f_overdue_deadline := DATE_SUB(@now, INTERVAL 2 HOUR);

SET @f_ended_departure := DATE_SUB(@now, INTERVAL 36 HOUR);
SET @f_ended_arrival := DATE_SUB(@now, INTERVAL 33 HOUR);
SET @f_ended_deadline := DATE_SUB(@now, INTERVAL 48 HOUR);

SET @f_old_departure := DATE_SUB(@now, INTERVAL 12 DAY);
SET @f_old_arrival := DATE_SUB(@now, INTERVAL 11 DAY);
SET @f_old_deadline := DATE_SUB(@now, INTERVAL 13 DAY);

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 'FUS6101', '上海', '成都', @f_active_departure, @f_active_arrival, 190, 2, JSON_ARRAY('午餐','加餐'), @f_active_deadline, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'FUS6101');

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 'FUS6202', '北京', '深圳', @f_overdue_departure, @f_overdue_arrival, 180, 1, JSON_ARRAY('正餐'), @f_overdue_deadline, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'FUS6202');

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 'FUS6303', '广州', '乌鲁木齐', @f_ended_departure, @f_ended_arrival, 290, 1, JSON_ARRAY('正餐'), @f_ended_deadline, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'FUS6303');

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, meal_times, selection_deadline, status, create_user, update_user, create_time, update_time)
SELECT 'FUS6404', '杭州', '西安', @f_old_departure, @f_old_arrival, 160, 1, JSON_ARRAY('早餐'), @f_old_deadline, 1, 1, 1, @now, @now
WHERE NOT EXISTS (SELECT 1 FROM flight_info WHERE flight_number = 'FUS6404');

-- 每次执行都刷新航班时间窗口，保证答辩演示时“进行中/逾期/已结束”状态稳定可复现
UPDATE flight_info
SET departure='上海', destination='成都', departure_time=@f_active_departure, arrival_time=@f_active_arrival,
    duration_minutes=190, meal_count=2, meal_times=JSON_ARRAY('午餐','加餐'), selection_deadline=@f_active_deadline,
    status=1, update_user=1, update_time=@now
WHERE flight_number='FUS6101';

UPDATE flight_info
SET departure='北京', destination='深圳', departure_time=@f_overdue_departure, arrival_time=@f_overdue_arrival,
    duration_minutes=180, meal_count=1, meal_times=JSON_ARRAY('正餐'), selection_deadline=@f_overdue_deadline,
    status=1, update_user=1, update_time=@now
WHERE flight_number='FUS6202';

UPDATE flight_info
SET departure='广州', destination='乌鲁木齐', departure_time=@f_ended_departure, arrival_time=@f_ended_arrival,
    duration_minutes=290, meal_count=1, meal_times=JSON_ARRAY('正餐'), selection_deadline=@f_ended_deadline,
    status=1, update_user=1, update_time=@now
WHERE flight_number='FUS6303';

UPDATE flight_info
SET departure='杭州', destination='西安', departure_time=@f_old_departure, arrival_time=@f_old_arrival,
    duration_minutes=160, meal_count=1, meal_times=JSON_ARRAY('早餐'), selection_deadline=@f_old_deadline,
    status=1, update_user=1, update_time=@now
WHERE flight_number='FUS6404';

SELECT id INTO @f_active_id FROM flight_info WHERE flight_number = 'FUS6101' ORDER BY id DESC LIMIT 1;
SELECT id INTO @f_overdue_id FROM flight_info WHERE flight_number = 'FUS6202' ORDER BY id DESC LIMIT 1;
SELECT id INTO @f_ended_id FROM flight_info WHERE flight_number = 'FUS6303' ORDER BY id DESC LIMIT 1;
SELECT id INTO @f_old_id FROM flight_info WHERE flight_number = 'FUS6404' ORDER BY id DESC LIMIT 1;

-- F) 航线-餐食映射（含舱位层级）
INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '上海', '成都', @dish_lowfat, 1, 3, 1
WHERE @dish_lowfat IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='上海' AND destination='成都' AND dish_id=@dish_lowfat AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '上海', '成都', @dish_beef, 1, 3, 2
WHERE @dish_beef IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='上海' AND destination='成都' AND dish_id=@dish_beef AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '上海', '成都', @dish_fish, 1, 3, 3
WHERE @dish_fish IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='上海' AND destination='成都' AND dish_id=@dish_fish AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '上海', '成都', @dish_spicy, 1, 3, 4
WHERE @dish_spicy IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='上海' AND destination='成都' AND dish_id=@dish_spicy AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '上海', '成都', @dish_breakfast1, 1, 1, 5
WHERE @dish_breakfast1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='上海' AND destination='成都' AND dish_id=@dish_breakfast1 AND IFNULL(cabin_type,3)=1);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '上海', '成都', @dish_yogurt, 1, 1, 6
WHERE @dish_yogurt IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='上海' AND destination='成都' AND dish_id=@dish_yogurt AND IFNULL(cabin_type,3)=1);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '北京', '深圳', @dish_beef, 1, 2, 1
WHERE @dish_beef IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='北京' AND destination='深圳' AND dish_id=@dish_beef AND IFNULL(cabin_type,3)=2);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '北京', '深圳', @dish_spicy, 1, 3, 2
WHERE @dish_spicy IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='北京' AND destination='深圳' AND dish_id=@dish_spicy AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '北京', '深圳', @dish_breakfast2, 1, 3, 3
WHERE @dish_breakfast2 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='北京' AND destination='深圳' AND dish_id=@dish_breakfast2 AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '广州', '乌鲁木齐', @dish_halal, 1, 3, 1
WHERE @dish_halal IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='广州' AND destination='乌鲁木齐' AND dish_id=@dish_halal AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '广州', '乌鲁木齐', @dish_lowfat, 1, 1, 2
WHERE @dish_lowfat IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='广州' AND destination='乌鲁木齐' AND dish_id=@dish_lowfat AND IFNULL(cabin_type,3)=1);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '广州', '乌鲁木齐', @dish_vegan, 1, 2, 3
WHERE @dish_vegan IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='广州' AND destination='乌鲁木齐' AND dish_id=@dish_vegan AND IFNULL(cabin_type,3)=2);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '杭州', '西安', @dish_breakfast1, 1, 3, 1
WHERE @dish_breakfast1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='杭州' AND destination='西安' AND dish_id=@dish_breakfast1 AND IFNULL(cabin_type,3)=3);

INSERT INTO flight_route_dish (departure, destination, dish_id, dish_source, cabin_type, sort)
SELECT '杭州', '西安', @dish_child, 1, 3, 2
WHERE @dish_child IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_route_dish WHERE departure='杭州' AND destination='西安' AND dish_id=@dish_child AND IFNULL(cabin_type,3)=3);

-- G) 用户画像样本（含异常用户）
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u1', '13900000001', '融合演示头等A', '110101199001011231', 1, @f_active_id, 1, @now, @now, 1, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u1');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u2', '13900000002', '融合演示商务B', '110101199202022232', 1, @f_active_id, 2, @now, @now, 0, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u2');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u3', '13900000003', '融合演示经济C', '110101199303033233', 1, @f_active_id, 3, @now, @now, 1, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u3');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u4', '13900000004', '协同用户D', '110101199404044234', 1, @f_active_id, 3, @now, @now, 1, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u4');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u5', '13900000005', '协同用户E', '110101199505055235', 1, @f_ended_id, 3, @now, @now, 0, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u5');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u6', '13900000006', '异常用户F-缺证件', NULL, 0, NULL, 3, @now, @now, 1, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u6');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u7', '13900000007', '逾期用户G', '110101199707077237', 1, @f_overdue_id, 3, @now, @now, 1, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u7');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u8', '13900000008', '异常用户H-未绑航班', '110101199808088238', 1, NULL, 2, @now, @now, 0, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u8');

INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
SELECT 'fusion-demo-u9', '13900000009', '异常用户I-偏好未完成', '110101199909099239', 0, @f_active_id, 3, @now, @now, 1, ''
WHERE NOT EXISTS (SELECT 1 FROM user WHERE openid = 'fusion-demo-u9');

-- 每次执行都回填到稳定状态
UPDATE user SET name='融合演示头等A', current_flight_id=@f_active_id, preference_completed=1, cabin_type=1, id_number='110101199001011231', update_time=@now WHERE openid='fusion-demo-u1';
UPDATE user SET name='融合演示商务B', current_flight_id=@f_active_id, preference_completed=1, cabin_type=2, id_number='110101199202022232', update_time=@now WHERE openid='fusion-demo-u2';
UPDATE user SET name='融合演示经济C', current_flight_id=@f_active_id, preference_completed=1, cabin_type=3, id_number='110101199303033233', update_time=@now WHERE openid='fusion-demo-u3';
UPDATE user SET name='协同用户D', current_flight_id=@f_active_id, preference_completed=1, cabin_type=3, id_number='110101199404044234', update_time=@now WHERE openid='fusion-demo-u4';
UPDATE user SET name='协同用户E', current_flight_id=@f_ended_id, preference_completed=1, cabin_type=3, id_number='110101199505055235', update_time=@now WHERE openid='fusion-demo-u5';
UPDATE user SET name='异常用户F-缺证件', current_flight_id=NULL, preference_completed=0, cabin_type=3, id_number=NULL, update_time=@now WHERE openid='fusion-demo-u6';
UPDATE user SET name='逾期用户G', current_flight_id=@f_overdue_id, preference_completed=1, cabin_type=3, id_number='110101199707077237', update_time=@now WHERE openid='fusion-demo-u7';
UPDATE user SET name='异常用户H-未绑航班', current_flight_id=NULL, preference_completed=1, cabin_type=2, id_number='110101199808088238', update_time=@now WHERE openid='fusion-demo-u8';
UPDATE user SET name='异常用户I-偏好未完成', current_flight_id=@f_active_id, preference_completed=0, cabin_type=3, id_number='110101199909099239', update_time=@now WHERE openid='fusion-demo-u9';

SELECT id INTO @u1 FROM user WHERE openid='fusion-demo-u1' LIMIT 1;
SELECT id INTO @u2 FROM user WHERE openid='fusion-demo-u2' LIMIT 1;
SELECT id INTO @u3 FROM user WHERE openid='fusion-demo-u3' LIMIT 1;
SELECT id INTO @u4 FROM user WHERE openid='fusion-demo-u4' LIMIT 1;
SELECT id INTO @u5 FROM user WHERE openid='fusion-demo-u5' LIMIT 1;
SELECT id INTO @u6 FROM user WHERE openid='fusion-demo-u6' LIMIT 1;
SELECT id INTO @u7 FROM user WHERE openid='fusion-demo-u7' LIMIT 1;
SELECT id INTO @u8 FROM user WHERE openid='fusion-demo-u8' LIMIT 1;
SELECT id INTO @u9 FROM user WHERE openid='fusion-demo-u9' LIMIT 1;

-- H) 偏好画像（影响 PMFUP + 标签）
INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u1, JSON_ARRAY(2), JSON_ARRAY('清淡','低脂','高蛋白'), JSON_ARRAY('花生'), '主偏好低脂高蛋白', @now, @now
WHERE @u1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u1);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u2, JSON_ARRAY(2), JSON_ARRAY('微辣','咸香'), JSON_ARRAY(), '偏好风味更重', @now, @now
WHERE @u2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u2);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u3, JSON_ARRAY(1), JSON_ARRAY('甜口','清淡'), JSON_ARRAY(), '偏好早餐与轻食', @now, @now
WHERE @u3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u3);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u4, JSON_ARRAY(2), JSON_ARRAY('清淡','低脂'), JSON_ARRAY(), '与用户A构造协同相似', @now, @now
WHERE @u4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u4);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u5, JSON_ARRAY(2), JSON_ARRAY('清淡','低脂'), JSON_ARRAY(), '与用户A构造协同相似', @now, @now
WHERE @u5 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u5);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u7, JSON_ARRAY(2), JSON_ARRAY('咸香'), JSON_ARRAY(), '用于逾期自动分配场景', @now, @now
WHERE @u7 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u7);

INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
SELECT @u8, JSON_ARRAY(3), JSON_ARRAY('咸香'), JSON_ARRAY(), '已完偏好但未绑航班', @now, @now
WHERE @u8 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = @u8);

UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(2), flavor_preferences=JSON_ARRAY('清淡','低脂','高蛋白'), allergens=JSON_ARRAY('花生'), dietary_notes='主偏好低脂高蛋白', update_time=@now WHERE user_id=@u1;
UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(2), flavor_preferences=JSON_ARRAY('微辣','咸香'), allergens=JSON_ARRAY(), dietary_notes='偏好风味更重', update_time=@now WHERE user_id=@u2;
UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(1), flavor_preferences=JSON_ARRAY('甜口','清淡'), allergens=JSON_ARRAY(), dietary_notes='偏好早餐与轻食', update_time=@now WHERE user_id=@u3;
UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(2), flavor_preferences=JSON_ARRAY('清淡','低脂'), allergens=JSON_ARRAY(), dietary_notes='与用户A构造协同相似', update_time=@now WHERE user_id=@u4;
UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(2), flavor_preferences=JSON_ARRAY('清淡','低脂'), allergens=JSON_ARRAY(), dietary_notes='与用户A构造协同相似', update_time=@now WHERE user_id=@u5;
UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(2), flavor_preferences=JSON_ARRAY('咸香'), allergens=JSON_ARRAY(), dietary_notes='用于逾期自动分配场景', update_time=@now WHERE user_id=@u7;
UPDATE user_preference SET meal_type_preferences=JSON_ARRAY(3), flavor_preferences=JSON_ARRAY('咸香'), allergens=JSON_ARRAY(), dietary_notes='已完偏好但未绑航班', update_time=@now WHERE user_id=@u8;

-- I) 公告（用户公告中心 + 管理端）
INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time)
SELECT @f_active_id, 'FUS6101 餐食预选开放', '推荐引擎已根据画像与历史行为生成候选餐单，请在截止前确认。', 1, 1, @now, @now
WHERE @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_announcement WHERE title='FUS6101 餐食预选开放');

INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time)
SELECT @f_overdue_id, 'FUS6202 预选已超时', '已进入逾期自动分配阶段，系统将按融合推荐自动确认餐食。', 1, 1, @now, @now
WHERE @f_overdue_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_announcement WHERE title='FUS6202 预选已超时');

INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time)
SELECT @f_ended_id, 'FUS6303 历史回访', '感谢体验本次机上餐食，欢迎在评分弹窗中反馈。', 0, 1, @now, @now
WHERE @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_announcement WHERE title='FUS6303 历史回访');

-- J) 餐食预选记录（手动确认 + 自动分配）
INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT 'SEL-FUS6101-U1-M1', 3, @u1, @f_active_id, 1, '12A', DATE_SUB(@now, INTERVAL 3 DAY), DATE_SUB(@now, INTERVAL 3 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM meal_selection WHERE user_id=@u1 AND flight_id=@f_active_id AND meal_order=1);

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT 'SEL-FUS6101-U1-M2', 3, @u1, @f_active_id, 2, '12A', DATE_SUB(@now, INTERVAL 2 DAY), DATE_SUB(@now, INTERVAL 2 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM meal_selection WHERE user_id=@u1 AND flight_id=@f_active_id AND meal_order=2);

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT 'SEL-FUS6101-U2-M1', 3, @u2, @f_active_id, 1, '15C', DATE_SUB(@now, INTERVAL 2 DAY), DATE_SUB(@now, INTERVAL 2 DAY)
WHERE @u2 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM meal_selection WHERE user_id=@u2 AND flight_id=@f_active_id AND meal_order=1);

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT 'SEL-FUS6303-U1-M1', 3, @u1, @f_ended_id, 1, '12A', DATE_SUB(@now, INTERVAL 1 DAY), DATE_SUB(@now, INTERVAL 1 DAY)
WHERE @u1 IS NOT NULL AND @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM meal_selection WHERE user_id=@u1 AND flight_id=@f_ended_id AND meal_order=1);

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
SELECT 'AUTO-FUS6404-U5-M1', 5, @u5, @f_old_id, 1, 'AUTO', DATE_SUB(@now, INTERVAL 10 DAY), DATE_SUB(@now, INTERVAL 10 DAY)
WHERE @u5 IS NOT NULL AND @f_old_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM meal_selection WHERE user_id=@u5 AND flight_id=@f_old_id AND meal_order=1);

-- K) 推荐日志：构造 PMFUP + PRMIDM + AMMBC 多源信号
SET @fb_click_u1 := CONCAT('CLICK:dishId=', @dish_lowfat, ':mealOrder=1');
SET @fb_manual_u1_active := CONCAT('MANUAL_SELECTED:dishId=', @dish_lowfat, ':mealOrder=1');
SET @fb_manual_u1_active_m2 := CONCAT('MANUAL_SELECTED_UPDATE:dishId=', @dish_fish, ':mealOrder=2');
SET @fb_manual_u1_ended := CONCAT('MANUAL_SELECTED:dishId=', @dish_lowfat, ':mealOrder=1');
SET @fb_manual_u2_active := CONCAT('MANUAL_SELECTED:dishId=', @dish_spicy, ':mealOrder=1');
SET @fb_manual_u2_ended := CONCAT('MANUAL_SELECTED:dishId=', @dish_beef, ':mealOrder=1');
SET @fb_manual_u3_old := CONCAT('MANUAL_SELECTED:dishId=', @dish_breakfast1, ':mealOrder=1');
SET @fb_manual_u4_active := CONCAT('MANUAL_SELECTED:dishId=', @dish_lowfat, ':mealOrder=1');
SET @fb_auto_u5_old := CONCAT('AUTO_SELECTED_OVERDUE:dishId=', @dish_lowfat);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u1, @f_active_id, JSON_ARRAY(@dish_lowfat, @dish_fish, @dish_beef), @alg, NULL, 'SEED_EXPOSURE_ALPHA', DATE_SUB(@now, INTERVAL 20 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY 'SEED_EXPOSURE_ALPHA');

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u1, @f_active_id, JSON_ARRAY(@dish_lowfat, @dish_fish, @dish_breakfast1), @alg, NULL, 'SEED_EXPOSURE_BETA', DATE_SUB(@now, INTERVAL 8 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY 'SEED_EXPOSURE_BETA');

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u1, @f_active_id, JSON_ARRAY(@dish_lowfat), @alg, NULL, @fb_click_u1, DATE_SUB(@now, INTERVAL 7 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY @fb_click_u1);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u1, @f_active_id, JSON_ARRAY(@dish_lowfat), @alg, 5, @fb_manual_u1_active, DATE_SUB(@now, INTERVAL 6 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY @fb_manual_u1_active);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u1, @f_active_id, JSON_ARRAY(@dish_fish), @alg, 4, @fb_manual_u1_active_m2, DATE_SUB(@now, INTERVAL 5 DAY)
WHERE @u1 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY @fb_manual_u1_active_m2);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u1, @f_ended_id, JSON_ARRAY(@dish_lowfat), @alg, 5, @fb_manual_u1_ended, DATE_SUB(@now, INTERVAL 2 DAY)
WHERE @u1 IS NOT NULL AND @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_ended_id AND BINARY user_feedback = BINARY @fb_manual_u1_ended);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u4, @f_active_id, JSON_ARRAY(@dish_lowfat, @dish_fish, @dish_beef), @alg, NULL, 'SEED_EXPOSURE_GAMMA', DATE_SUB(@now, INTERVAL 12 DAY)
WHERE @u4 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u4 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY 'SEED_EXPOSURE_GAMMA');

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u4, @f_active_id, JSON_ARRAY(@dish_lowfat), @alg, 4, @fb_manual_u4_active, DATE_SUB(@now, INTERVAL 4 DAY)
WHERE @u4 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u4 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY @fb_manual_u4_active);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u5, @f_ended_id, JSON_ARRAY(@dish_lowfat, @dish_fish, @dish_yogurt), @alg, NULL, 'SEED_EXPOSURE_DELTA', DATE_SUB(@now, INTERVAL 9 DAY)
WHERE @u5 IS NOT NULL AND @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u5 AND flight_id=@f_ended_id AND BINARY user_feedback = BINARY 'SEED_EXPOSURE_DELTA');

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u5, @f_old_id, JSON_ARRAY(@dish_lowfat), @alg, NULL, @fb_auto_u5_old, DATE_SUB(@now, INTERVAL 10 DAY)
WHERE @u5 IS NOT NULL AND @f_old_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u5 AND flight_id=@f_old_id AND BINARY user_feedback = BINARY @fb_auto_u5_old);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u2, @f_active_id, JSON_ARRAY(@dish_spicy, @dish_beef, @dish_lowfat), @alg, NULL, 'SEED_EXPOSURE_EPSILON', DATE_SUB(@now, INTERVAL 11 DAY)
WHERE @u2 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u2 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY 'SEED_EXPOSURE_EPSILON');

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u2, @f_active_id, JSON_ARRAY(@dish_spicy), @alg, 3, @fb_manual_u2_active, DATE_SUB(@now, INTERVAL 3 DAY)
WHERE @u2 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u2 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY @fb_manual_u2_active);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u2, @f_ended_id, JSON_ARRAY(@dish_beef), @alg, NULL, @fb_manual_u2_ended, DATE_SUB(@now, INTERVAL 2 DAY)
WHERE @u2 IS NOT NULL AND @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u2 AND flight_id=@f_ended_id AND BINARY user_feedback = BINARY @fb_manual_u2_ended);

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u3, @f_active_id, JSON_ARRAY(@dish_breakfast1, @dish_breakfast2, @dish_yogurt), @alg, NULL, 'SEED_EXPOSURE_ZETA', DATE_SUB(@now, INTERVAL 10 DAY)
WHERE @u3 IS NOT NULL AND @f_active_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u3 AND flight_id=@f_active_id AND BINARY user_feedback = BINARY 'SEED_EXPOSURE_ZETA');

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
SELECT @u3, @f_old_id, JSON_ARRAY(@dish_breakfast1), @alg, NULL, @fb_manual_u3_old, DATE_SUB(@now, INTERVAL 9 DAY)
WHERE @u3 IS NOT NULL AND @f_old_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM recommendation_log WHERE user_id=@u3 AND flight_id=@f_old_id AND BINARY user_feedback = BINARY @fb_manual_u3_old);

-- L) 评分任务：构造 SUBMITTED / PENDING / DEFERRED / EXPIRED 四类状态
SELECT id INTO @log_u1_ended FROM recommendation_log WHERE user_id=@u1 AND flight_id=@f_ended_id AND BINARY user_feedback = BINARY @fb_manual_u1_ended ORDER BY id DESC LIMIT 1;
SELECT id INTO @log_u2_ended FROM recommendation_log WHERE user_id=@u2 AND flight_id=@f_ended_id AND BINARY user_feedback = BINARY @fb_manual_u2_ended ORDER BY id DESC LIMIT 1;
SELECT id INTO @log_u3_old FROM recommendation_log WHERE user_id=@u3 AND flight_id=@f_old_id AND BINARY user_feedback = BINARY @fb_manual_u3_old ORDER BY id DESC LIMIT 1;
SELECT id INTO @log_u5_old FROM recommendation_log WHERE user_id=@u5 AND flight_id=@f_old_id AND BINARY user_feedback = BINARY @fb_auto_u5_old ORDER BY id DESC LIMIT 1;

INSERT INTO flight_service_rating (user_id, flight_id, source_log_id, rating_status, first_visible_at, last_visible_at, next_remind_at, defer_count, submitted_at, expire_at, channel, create_time, update_time)
SELECT @u1, @f_ended_id, @log_u1_ended, 'SUBMITTED', DATE_SUB(@now, INTERVAL 3 DAY), DATE_SUB(@now, INTERVAL 1 DAY), NULL, 0, DATE_SUB(@now, INTERVAL 1 DAY), DATE_ADD(@now, INTERVAL 6 DAY), 'miniapp', @now, @now
WHERE @u1 IS NOT NULL AND @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_service_rating WHERE user_id=@u1 AND flight_id=@f_ended_id);

INSERT INTO flight_service_rating (user_id, flight_id, source_log_id, rating_status, first_visible_at, last_visible_at, next_remind_at, defer_count, submitted_at, expire_at, channel, create_time, update_time)
SELECT @u2, @f_ended_id, @log_u2_ended, 'PENDING', DATE_SUB(@now, INTERVAL 2 DAY), DATE_SUB(@now, INTERVAL 2 HOUR), DATE_SUB(@now, INTERVAL 30 MINUTE), 0, NULL, DATE_ADD(@now, INTERVAL 5 DAY), 'miniapp', @now, @now
WHERE @u2 IS NOT NULL AND @f_ended_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_service_rating WHERE user_id=@u2 AND flight_id=@f_ended_id);

INSERT INTO flight_service_rating (user_id, flight_id, source_log_id, rating_status, first_visible_at, last_visible_at, next_remind_at, defer_count, submitted_at, expire_at, channel, create_time, update_time)
SELECT @u3, @f_old_id, @log_u3_old, 'DEFERRED', DATE_SUB(@now, INTERVAL 8 DAY), DATE_SUB(@now, INTERVAL 2 HOUR), DATE_SUB(@now, INTERVAL 2 HOUR), 2, NULL, DATE_ADD(@now, INTERVAL 1 DAY), 'miniapp', @now, @now
WHERE @u3 IS NOT NULL AND @f_old_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_service_rating WHERE user_id=@u3 AND flight_id=@f_old_id);

INSERT INTO flight_service_rating (user_id, flight_id, source_log_id, rating_status, first_visible_at, last_visible_at, next_remind_at, defer_count, submitted_at, expire_at, channel, create_time, update_time)
SELECT @u5, @f_old_id, @log_u5_old, 'EXPIRED', DATE_SUB(@now, INTERVAL 9 DAY), DATE_SUB(@now, INTERVAL 1 DAY), DATE_SUB(@now, INTERVAL 3 DAY), 1, NULL, DATE_SUB(@now, INTERVAL 1 DAY), 'miniapp', @now, @now
WHERE @u5 IS NOT NULL AND @f_old_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM flight_service_rating WHERE user_id=@u5 AND flight_id=@f_old_id);

UPDATE flight_service_rating
SET source_log_id=@log_u1_ended,
    rating_status='SUBMITTED',
    rating_score=5,
    submitted_at=DATE_SUB(@now, INTERVAL 1 DAY),
    next_remind_at=NULL,
    defer_count=0,
    expire_at=DATE_ADD(@now, INTERVAL 6 DAY),
    last_visible_at=DATE_SUB(@now, INTERVAL 1 DAY),
    update_time=@now
WHERE user_id=@u1 AND flight_id=@f_ended_id;

UPDATE flight_service_rating
SET source_log_id=@log_u2_ended,
    rating_status='PENDING',
    rating_score=NULL,
    submitted_at=NULL,
    next_remind_at=DATE_SUB(@now, INTERVAL 30 MINUTE),
    defer_count=0,
    expire_at=DATE_ADD(@now, INTERVAL 5 DAY),
    last_visible_at=DATE_SUB(@now, INTERVAL 2 HOUR),
    update_time=@now
WHERE user_id=@u2 AND flight_id=@f_ended_id;

UPDATE flight_service_rating
SET source_log_id=@log_u3_old,
    rating_status='DEFERRED',
    rating_score=NULL,
    submitted_at=NULL,
    next_remind_at=DATE_SUB(@now, INTERVAL 2 HOUR),
    defer_count=2,
    expire_at=DATE_ADD(@now, INTERVAL 1 DAY),
    last_visible_at=DATE_SUB(@now, INTERVAL 2 HOUR),
    update_time=@now
WHERE user_id=@u3 AND flight_id=@f_old_id;

UPDATE flight_service_rating
SET source_log_id=@log_u5_old,
    rating_status='EXPIRED',
    rating_score=NULL,
    submitted_at=NULL,
    next_remind_at=DATE_SUB(@now, INTERVAL 3 DAY),
    defer_count=1,
    expire_at=DATE_SUB(@now, INTERVAL 1 DAY),
    last_visible_at=DATE_SUB(@now, INTERVAL 1 DAY),
    update_time=@now
WHERE user_id=@u5 AND flight_id=@f_old_id;

UPDATE recommendation_log SET user_rating = 5 WHERE id = @log_u1_ended;

-- M) 规模化扩容：批量生成可答辩展示数据（默认 72 名旅客）
-- 调优建议：答辩现场可将 @bulk_user_count 提升到 90~120，观察算法排序与闭环看板变化
SET @bulk_start_index := 10;
SET @bulk_user_count := 72;
SET @bulk_end_index := @bulk_start_index + @bulk_user_count - 1;

DROP PROCEDURE IF EXISTS sp_seed_fused_bulk_demo;
DELIMITER $$

CREATE PROCEDURE sp_seed_fused_bulk_demo()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE v_openid VARCHAR(64);
  DECLARE v_phone VARCHAR(11);
  DECLARE v_name VARCHAR(64);
  DECLARE v_id_number VARCHAR(18);
  DECLARE v_user_id BIGINT;
  DECLARE v_cabin TINYINT;
  DECLARE v_gender TINYINT;
  DECLARE v_pref_completed TINYINT;
  DECLARE v_current_flight BIGINT;
  DECLARE v_main_dish BIGINT;
  DECLARE v_second_dish BIGINT;
  DECLARE v_selection_status TINYINT;
  DECLARE v_seed VARCHAR(16);
  DECLARE v_manual_feedback VARCHAR(255);
  DECLARE v_rating_status VARCHAR(16);
  DECLARE v_rating_score TINYINT;
  DECLARE v_log_id BIGINT;

  SET i = IFNULL(@bulk_start_index, 10);

  WHILE i <= IFNULL(@bulk_end_index, 81) DO
    SET v_seed = LPAD(i, 3, '0');
    SET v_openid = CONCAT('fusion-bulk-u', v_seed);
    SET v_phone = CONCAT('137', LPAD(i, 8, '0'));
    SET v_name = CONCAT('融合批量旅客', v_seed);
    SET v_gender = MOD(i, 2);

    SET v_cabin = CASE MOD(i, 10)
      WHEN 0 THEN 1
      WHEN 1 THEN 2
      ELSE 3
    END;

    SET v_pref_completed = CASE WHEN MOD(i, 13) = 0 THEN 0 ELSE 1 END;
    SET v_current_flight = CASE MOD(i, 6)
      WHEN 0 THEN @f_active_id
      WHEN 1 THEN @f_active_id
      WHEN 2 THEN @f_overdue_id
      WHEN 3 THEN @f_ended_id
      WHEN 4 THEN @f_old_id
      ELSE @f_active_id
    END;

    SET v_id_number = CONCAT('3201011990',
                 LPAD(MOD(i, 12) + 1, 2, '0'),
                 LPAD(MOD(i, 27) + 1, 2, '0'),
                 LPAD(i, 4, '0'));

    IF MOD(i, 17) = 0 THEN
      SET v_id_number = NULL;
    END IF;
    IF MOD(i, 19) = 0 THEN
      SET v_current_flight = NULL;
    END IF;

    INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, cabin_type, create_time, update_time, gender, pic)
    SELECT v_openid, v_phone, v_name, v_id_number, v_pref_completed, v_current_flight, v_cabin, @now, @now, v_gender, ''
    WHERE NOT EXISTS (SELECT 1 FROM user WHERE BINARY openid = BINARY v_openid);

    UPDATE user
    SET phone = v_phone,
      name = v_name,
      id_number = v_id_number,
      preference_completed = v_pref_completed,
      current_flight_id = v_current_flight,
      cabin_type = v_cabin,
      gender = v_gender,
      update_time = @now
    WHERE BINARY openid = BINARY v_openid;

    SELECT id INTO v_user_id FROM user WHERE BINARY openid = BINARY v_openid LIMIT 1;

    IF v_pref_completed = 1 THEN
      INSERT INTO user_preference (user_id, meal_type_preferences, flavor_preferences, allergens, dietary_notes, create_time, update_time)
      SELECT v_user_id,
           CASE MOD(i, 4)
             WHEN 0 THEN JSON_ARRAY(2)
             WHEN 1 THEN JSON_ARRAY(2)
             WHEN 2 THEN JSON_ARRAY(1)
             ELSE JSON_ARRAY(2)
           END,
           CASE MOD(i, 4)
             WHEN 0 THEN JSON_ARRAY('清淡','低脂','高蛋白')
             WHEN 1 THEN JSON_ARRAY('微辣','咸香')
             WHEN 2 THEN JSON_ARRAY('甜口','清淡')
             ELSE JSON_ARRAY('咸香','热食')
           END,
           JSON_ARRAY(),
           CONCAT('bulk-seed-', v_seed),
           @now, @now
      WHERE v_user_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM user_preference WHERE user_id = v_user_id);

      UPDATE user_preference
      SET meal_type_preferences = CASE MOD(i, 4)
          WHEN 0 THEN JSON_ARRAY(2)
          WHEN 1 THEN JSON_ARRAY(2)
          WHEN 2 THEN JSON_ARRAY(1)
          ELSE JSON_ARRAY(2)
        END,
        flavor_preferences = CASE MOD(i, 4)
          WHEN 0 THEN JSON_ARRAY('清淡','低脂','高蛋白')
          WHEN 1 THEN JSON_ARRAY('微辣','咸香')
          WHEN 2 THEN JSON_ARRAY('甜口','清淡')
          ELSE JSON_ARRAY('咸香','热食')
        END,
        allergens = JSON_ARRAY(),
        dietary_notes = CONCAT('bulk-seed-', v_seed),
        update_time = @now
      WHERE user_id = v_user_id;
    ELSE
      DELETE FROM user_preference WHERE user_id = v_user_id;
    END IF;

    IF v_user_id IS NOT NULL AND v_current_flight IS NOT NULL AND v_pref_completed = 1 THEN
      SET v_main_dish = CASE MOD(i, 4)
        WHEN 0 THEN @dish_lowfat
        WHEN 1 THEN @dish_spicy
        WHEN 2 THEN @dish_breakfast1
        ELSE @dish_beef
      END;
      SET v_second_dish = CASE MOD(i, 4)
        WHEN 0 THEN @dish_fish
        WHEN 1 THEN @dish_beef
        WHEN 2 THEN @dish_yogurt
        ELSE @dish_lowfat
      END;

      SET v_selection_status = CASE
        WHEN v_current_flight IN (@f_overdue_id, @f_old_id) AND MOD(i, 5) = 0 THEN 5
        ELSE 3
      END;

      INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, seat_number, create_time, update_time)
      SELECT CONCAT('SEL-BULK-U', v_seed, '-M1'),
           v_selection_status,
           v_user_id,
           v_current_flight,
           1,
           CONCAT(LPAD(MOD(i, 60) + 1, 2, '0'), CHAR(65 + MOD(i, 6))),
           DATE_SUB(@now, INTERVAL MOD(i, 14) DAY),
           @now
      WHERE NOT EXISTS (
        SELECT 1 FROM meal_selection
        WHERE user_id = v_user_id AND flight_id = v_current_flight AND meal_order = 1
      );

      UPDATE meal_selection
      SET status = v_selection_status,
        update_time = @now
      WHERE user_id = v_user_id AND flight_id = v_current_flight AND meal_order = 1;

      INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
      SELECT v_user_id, v_current_flight, JSON_ARRAY(v_main_dish, v_second_dish, @dish_yogurt), @alg, NULL,
           CONCAT('SEED_BULK_EXPOSURE_U', v_seed),
           DATE_SUB(@now, INTERVAL 18 - MOD(i, 11) DAY)
      WHERE NOT EXISTS (
        SELECT 1 FROM recommendation_log
        WHERE user_id = v_user_id
          AND flight_id = v_current_flight
          AND BINARY user_feedback = BINARY CONCAT('SEED_BULK_EXPOSURE_U', v_seed)
      );

      INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
      SELECT v_user_id, v_current_flight, JSON_ARRAY(v_main_dish), @alg, NULL,
           CONCAT('CLICK:dishId=', v_main_dish, ':mealOrder=1:seed=bulkU', v_seed),
           DATE_SUB(@now, INTERVAL 10 - MOD(i, 5) DAY)
      WHERE NOT EXISTS (
        SELECT 1 FROM recommendation_log
        WHERE user_id = v_user_id
          AND flight_id = v_current_flight
          AND BINARY user_feedback = BINARY CONCAT('CLICK:dishId=', v_main_dish, ':mealOrder=1:seed=bulkU', v_seed)
      );

      SET v_manual_feedback = CASE
        WHEN v_selection_status = 5
          THEN CONCAT('AUTO_SELECTED_OVERDUE:dishId=', v_main_dish, ':seed=bulkU', v_seed)
        ELSE CONCAT('MANUAL_SELECTED:dishId=', v_main_dish, ':mealOrder=1:seed=bulkU', v_seed)
      END;

      INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
      SELECT v_user_id,
           v_current_flight,
           JSON_ARRAY(v_main_dish),
           @alg,
           CASE WHEN MOD(i, 7) IN (0, 1, 2, 3) THEN 5 ELSE 4 END,
           v_manual_feedback,
           DATE_SUB(@now, INTERVAL 6 - MOD(i, 4) DAY)
      WHERE NOT EXISTS (
        SELECT 1 FROM recommendation_log
        WHERE user_id = v_user_id
          AND flight_id = v_current_flight
          AND BINARY user_feedback = BINARY v_manual_feedback
      );

      IF MOD(i, 6) = 0 THEN
        INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, algorithm_type, user_rating, user_feedback, create_time)
        SELECT v_user_id,
             v_current_flight,
             JSON_ARRAY(v_second_dish),
             @alg,
             4,
             CONCAT('MANUAL_SELECTED_UPDATE:dishId=', v_second_dish, ':mealOrder=1:seed=bulkU', v_seed),
             DATE_SUB(@now, INTERVAL 2 DAY)
        WHERE NOT EXISTS (
          SELECT 1 FROM recommendation_log
          WHERE user_id = v_user_id
            AND flight_id = v_current_flight
            AND BINARY user_feedback = BINARY CONCAT('MANUAL_SELECTED_UPDATE:dishId=', v_second_dish, ':mealOrder=1:seed=bulkU', v_seed)
        );
      END IF;

      IF v_current_flight IN (@f_ended_id, @f_old_id) THEN
        SET v_log_id = NULL;
        SELECT id INTO v_log_id
        FROM recommendation_log
        WHERE user_id = v_user_id
          AND flight_id = v_current_flight
           AND (BINARY user_feedback = BINARY v_manual_feedback
             OR BINARY user_feedback LIKE BINARY CONCAT('MANUAL_SELECTED_UPDATE:%seed=bulkU', v_seed))
        ORDER BY id DESC
        LIMIT 1;

        SET v_rating_status = CASE MOD(i, 4)
          WHEN 0 THEN 'SUBMITTED'
          WHEN 1 THEN 'PENDING'
          WHEN 2 THEN 'DEFERRED'
          ELSE 'EXPIRED'
        END;
        SET v_rating_score = CASE WHEN v_rating_status = 'SUBMITTED' THEN 4 + MOD(i, 2) ELSE NULL END;

        INSERT INTO flight_service_rating
          (user_id, flight_id, source_log_id, rating_score, rating_status,
           first_visible_at, last_visible_at, next_remind_at, defer_count,
           submitted_at, expire_at, channel, create_time, update_time)
        VALUES
          (v_user_id, v_current_flight, v_log_id, v_rating_score, v_rating_status,
           DATE_SUB(@now, INTERVAL 5 DAY),
           DATE_SUB(@now, INTERVAL 1 DAY),
           CASE
             WHEN v_rating_status = 'PENDING' THEN DATE_SUB(@now, INTERVAL 20 MINUTE)
             WHEN v_rating_status = 'DEFERRED' THEN DATE_SUB(@now, INTERVAL 3 HOUR)
             ELSE NULL
           END,
           CASE WHEN v_rating_status = 'DEFERRED' THEN 1 + MOD(i, 2) ELSE 0 END,
           CASE WHEN v_rating_status = 'SUBMITTED' THEN DATE_SUB(@now, INTERVAL 1 DAY) ELSE NULL END,
           CASE
             WHEN v_rating_status = 'EXPIRED' THEN DATE_SUB(@now, INTERVAL 1 DAY)
             ELSE DATE_ADD(@now, INTERVAL 6 DAY)
           END,
           'miniapp',
           @now,
           @now)
        ON DUPLICATE KEY UPDATE
          source_log_id = VALUES(source_log_id),
          rating_score = VALUES(rating_score),
          rating_status = VALUES(rating_status),
          first_visible_at = VALUES(first_visible_at),
          last_visible_at = VALUES(last_visible_at),
          next_remind_at = VALUES(next_remind_at),
          defer_count = VALUES(defer_count),
          submitted_at = VALUES(submitted_at),
          expire_at = VALUES(expire_at),
          update_time = VALUES(update_time);

        IF v_rating_status = 'SUBMITTED' AND v_log_id IS NOT NULL THEN
          UPDATE recommendation_log SET user_rating = v_rating_score WHERE id = v_log_id;
        END IF;
      END IF;
    END IF;

    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;

CALL sp_seed_fused_bulk_demo();
DROP PROCEDURE IF EXISTS sp_seed_fused_bulk_demo;

-- N) 验证输出（便于快速检查系统各模块）
SELECT account, name, status FROM employee WHERE account IN ('admin_demo', 'admin');

SELECT flight_number, departure, destination, departure_time, selection_deadline, status
FROM flight_info
WHERE flight_number IN ('FUS6101','FUS6202','FUS6303','FUS6404')
ORDER BY flight_number;

SELECT id, name, openid, cabin_type, current_flight_id, preference_completed,
       CASE
           WHEN id_number IS NULL OR TRIM(id_number) = '' THEN '缺少身份证'
           WHEN current_flight_id IS NULL THEN '缺少航班绑定'
           WHEN IFNULL(preference_completed, 0) = 0 THEN '偏好未完成'
           ELSE '正常'
       END AS exceptionType
FROM user
WHERE openid LIKE 'fusion-demo-%'
ORDER BY id;

SELECT user_id, flight_id, recommended_dishes, user_feedback, user_rating, create_time
FROM recommendation_log
WHERE user_id IN (@u1,@u2,@u3,@u4,@u5)
ORDER BY id DESC
LIMIT 30;

SELECT rating_status, COUNT(*) AS cnt
FROM flight_service_rating
GROUP BY rating_status
ORDER BY rating_status;

SELECT COUNT(*) AS bulkUserCount
FROM user
WHERE openid LIKE 'fusion-bulk-u%';

SELECT COUNT(*) AS bulkPreferenceCount
FROM user_preference up
      INNER JOIN user u ON u.id = up.user_id
WHERE u.openid LIKE 'fusion-bulk-u%';

SELECT IFNULL(fi.flight_number, 'UNBOUND') AS flightNumber,
     COUNT(*) AS passengerCount
FROM user u
      LEFT JOIN flight_info fi ON fi.id = u.current_flight_id
WHERE u.openid LIKE 'fusion-bulk-u%'
GROUP BY IFNULL(fi.flight_number, 'UNBOUND')
ORDER BY passengerCount DESC, flightNumber;

SELECT CASE
        WHEN rl.user_feedback LIKE 'SEED_BULK_EXPOSURE_%' THEN 'SEED_EXPOSURE'
        WHEN rl.user_feedback LIKE 'CLICK:%' THEN 'CLICK'
        WHEN rl.user_feedback LIKE 'MANUAL_SELECTED_UPDATE:%' THEN 'MANUAL_SELECTED_UPDATE'
        WHEN rl.user_feedback LIKE 'MANUAL_SELECTED:%' THEN 'MANUAL_SELECTED'
        WHEN rl.user_feedback LIKE 'AUTO_SELECTED_OVERDUE:%' THEN 'AUTO_SELECTED_OVERDUE'
        ELSE 'OTHER'
     END AS feedbackType,
     COUNT(*) AS cnt
FROM recommendation_log rl
WHERE rl.user_feedback LIKE '%seed=bulkU%'
  OR rl.user_feedback LIKE 'SEED_BULK_EXPOSURE_%'
GROUP BY feedbackType
ORDER BY cnt DESC;

SELECT fr.rating_status,
     COUNT(*) AS cnt
FROM flight_service_rating fr
      INNER JOIN user u ON u.id = fr.user_id
WHERE u.openid LIKE 'fusion-bulk-u%'
GROUP BY fr.rating_status
ORDER BY fr.rating_status;

SELECT COUNT(*) AS recommendCount FROM recommendation_log;
SELECT COUNT(*) AS preferenceUserCount FROM user_preference;
SELECT COUNT(*) AS selectionCount FROM meal_selection;
SELECT IFNULL(AVG(user_rating), 0) AS avgRating FROM recommendation_log WHERE user_rating IS NOT NULL;
