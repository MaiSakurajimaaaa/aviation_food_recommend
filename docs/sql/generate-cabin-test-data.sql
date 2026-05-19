-- ============================================================
-- 航空餐食推荐系统 — 舱位差异化测试数据生成 v2
-- 使用变量捕获ID，避免硬编码，可重复执行
-- ============================================================
USE aviation_food_recommend;

-- ============================================================
-- 1. 清理本次脚本可能产生过的旧数据
-- ============================================================
DELETE FROM meal_selection WHERE user_id IN (SELECT id FROM (SELECT id FROM user WHERE openid LIKE 'wx_fc%' OR openid LIKE 'wx_bc%' OR openid LIKE 'wx_ec%') t);
DELETE FROM recommendation_log WHERE user_id IN (SELECT id FROM (SELECT id FROM user WHERE openid LIKE 'wx_fc%' OR openid LIKE 'wx_bc%' OR openid LIKE 'wx_ec%') t);
DELETE FROM flight_service_rating WHERE user_id IN (SELECT id FROM (SELECT id FROM user WHERE openid LIKE 'wx_fc%' OR openid LIKE 'wx_bc%' OR openid LIKE 'wx_ec%') t);
DELETE FROM flight_dish WHERE dish_id IN (SELECT id FROM (SELECT id FROM dish WHERE name LIKE '%菲力%' OR name LIKE '%鹅肝%' OR name LIKE '%龙虾%' OR name LIKE '%刺身%' OR name LIKE '%三文鱼%' OR name LIKE '%松露%' OR name LIKE '%羊排%' OR name LIKE '%鱼子酱%' OR name LIKE '%宫保虾球%' OR name LIKE '%鲍鱼%' OR name LIKE '%黑椒牛柳%' OR name LIKE '%咖喱鸡肉%' OR name LIKE '%银鳕鱼%' OR name LIKE '%叉烧%' OR name LIKE '%XO酱%' OR name LIKE '%照烧%' OR name LIKE '%红烧牛肉面%' OR name LIKE '%宫保鸡丁盖饭%' OR name LIKE '%番茄鸡蛋%' OR name LIKE '%鱼香肉丝%' OR name LIKE '%回锅肉%' OR name LIKE '%香菇滑鸡%' OR name LIKE '%麻婆豆腐%' OR name LIKE '%清炒时蔬%' OR name LIKE '%鸡蛋三明治%' OR name LIKE '%什锦炒饭%') t);
DELETE FROM user WHERE openid LIKE 'wx_fc%' OR openid LIKE 'wx_bc%' OR openid LIKE 'wx_ec%';
DELETE FROM flight_info WHERE flight_number IN ('FUS8001','FUS8002','FUS8003','FUS8004','FUS8005','FUS8006');
DELETE FROM dish WHERE name LIKE '%菲力%' OR name LIKE '%鹅肝%' OR name LIKE '%龙虾%' OR name LIKE '%刺身%' OR name LIKE '%三文鱼%' OR name LIKE '%松露%' OR name LIKE '%羊排%' OR name LIKE '%鱼子酱%' OR name LIKE '%宫保虾球%' OR name LIKE '%鲍鱼%' OR name LIKE '%黑椒牛柳%' OR name LIKE '%咖喱鸡肉%' OR name LIKE '%银鳕鱼%' OR name LIKE '%叉烧%' OR name LIKE '%XO酱%' OR name LIKE '%照烧%' OR name LIKE '%红烧牛肉面%' OR name LIKE '%宫保鸡丁盖饭%' OR name LIKE '%番茄鸡蛋%' OR name LIKE '%鱼香肉丝%' OR name LIKE '%回锅肉%' OR name LIKE '%香菇滑鸡%' OR name LIKE '%麻婆豆腐%' OR name LIKE '%清炒时蔬%' OR name LIKE '%鸡蛋三明治%' OR name LIKE '%什锦炒饭%';

-- ============================================================
-- 2. 菜品
-- ============================================================
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('澳洲安格斯菲力牛排', 2, 2, '["咸香","高蛋白"]', 1, 60, '澳洲M7安格斯菲力配黑松露红酒汁'),
('法式香煎鹅肝', 2, 2, '["咸香","高蛋白"]', 1, 40, '法国鹅肝配无花果酱与烤法棍'),
('波士顿龙虾意面', 2, 2, '["咸香","微辣"]', 1, 50, '整只波士顿龙虾配手工宽面'),
('日式刺身拼盘', 1, 2, '["清淡","高蛋白","低脂"]', 1, 45, '三文鱼金枪鱼甜虾刺身'),
('挪威烟熏三文鱼贝果', 2, 2, '["咸香","高蛋白"]', 1, 55, '挪威烟熏三文鱼配奶油芝士贝果'),
('松露野菌奶油汤', 3, 4, '["清淡","低脂"]', 1, 70, '意大利黑松露配三种野菌浓汤'),
('慢烤新西兰羊排', 2, 2, '["咸香","高蛋白"]', 1, 40, '新西兰草饲羊排配迷迭香红酒汁'),
('鱼子酱配俄式薄饼', 2, 2, '["咸香","甜口"]', 1, 30, '俄罗斯鲟鱼子酱配薄饼与酸奶油');
SET @dish_fc1 = LAST_INSERT_ID();  -- 8道头等舱起始ID

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('宫保虾球配蛋炒饭', 2, 2, '["微辣","咸香"]', 1, 80, '大虾球宫保酱汁配茉莉香米蛋炒饭'),
('红烧鲍鱼捞面', 2, 2, '["咸香","高蛋白"]', 1, 70, '鲜活鲍鱼红烧酱汁配手工拉面'),
('黑椒牛柳炒乌冬', 2, 2, '["咸香","微辣"]', 1, 85, '澳洲牛柳配日式乌冬面黑椒汁'),
('咖喱鸡肉配香米', 2, 2, '["微辣","咸香"]', 1, 90, '泰式黄咖喱鸡腿肉配巴斯马蒂香米'),
('清蒸银鳕鱼配时蔬', 2, 2, '["清淡","低脂","高蛋白"]', 1, 75, '阿拉斯加银鳕鱼清蒸配时令蔬菜'),
('叉烧双拼饭', 2, 2, '["咸香","甜口"]', 1, 95, '蜜汁叉烧拼玫瑰豉油鸡配丝苗米饭'),
('XO酱海鲜炒饭', 2, 2, '["微辣","咸香"]', 1, 100, '瑶柱虾仁鱿鱼XO酱炒饭'),
('照烧鳗鱼饭', 2, 2, '["甜口","咸香"]', 1, 80, '蒲烧鳗鱼照烧汁配越光米饭');

INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('红烧牛肉面', 2, 2, '["咸香","微辣"]', 1, 150, '红烧牛腱子肉配手工拉面与时蔬'),
('宫保鸡丁盖饭', 2, 2, '["微辣","咸香"]', 1, 150, '经典宫保鸡丁配白米饭'),
('番茄鸡蛋打卤面', 2, 2, '["清淡","甜口"]', 1, 150, '新鲜番茄炒蛋配手工面条'),
('鱼香肉丝饭', 2, 2, '["微辣","甜口"]', 1, 140, '经典鱼香肉丝配白米饭'),
('回锅肉盖饭', 2, 2, '["微辣","咸香"]', 1, 140, '经典川味回锅肉配白米饭'),
('香菇滑鸡饭', 2, 2, '["清淡","咸香"]', 1, 140, '香菇蒸滑鸡配白米饭'),
('麻婆豆腐饭', 2, 4, '["微辣","咸香"]', 1, 120, '川味麻婆豆腐配白米饭(素食)'),
('清炒时蔬小米粥', 2, 4, '["清淡","低脂"]', 1, 130, '当季时蔬清炒配小米粥(素食)'),
('鸡蛋三明治套餐', 2, 2, '["清淡","低脂"]', 1, 150, '火腿鸡蛋三明治配鲜切水果酸奶'),
('什锦炒饭', 2, 2, '["咸香"]', 1, 150, '火腿青豆鸡蛋什锦炒饭');

-- ============================================================
-- 3. 航班：逐个插入并捕获ID
-- ============================================================
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time)
VALUES ('FUS8001','北京','上海','2026-05-20 08:00:00','2026-05-20 10:30:00',150,1,'2026-05-19 20:00:00',1,1,NOW());
SET @f1 = LAST_INSERT_ID();

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time)
VALUES ('FUS8002','上海','成都','2026-05-22 07:00:00','2026-05-22 10:00:00',180,2,'2026-05-21 18:00:00',1,1,NOW());
SET @f2 = LAST_INSERT_ID();

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time)
VALUES ('FUS8003','广州','北京','2026-05-25 09:00:00','2026-05-25 12:30:00',210,2,'2026-05-24 20:00:00',1,1,NOW());
SET @f3 = LAST_INSERT_ID();

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time)
VALUES ('FUS8004','深圳','乌鲁木齐','2026-05-28 06:30:00','2026-05-28 11:30:00',300,2,'2026-05-27 18:00:00',1,1,NOW());
SET @f4 = LAST_INSERT_ID();

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time)
VALUES ('FUS8005','成都','杭州','2026-06-01 10:00:00','2026-06-01 12:30:00',150,1,'2026-05-31 22:00:00',1,1,NOW());
SET @f5 = LAST_INSERT_ID();

INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time)
VALUES ('FUS8006','北京','三亚','2026-06-05 07:30:00','2026-06-05 11:30:00',240,2,'2026-06-04 18:00:00',1,1,NOW());
SET @f6 = LAST_INSERT_ID();

-- ============================================================
-- 4. 航线-菜品绑定（使用变量）
-- ============================================================
-- FUS8001 头等
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f1,@dish_fc1,1,1),(@f1,@dish_fc1+1,1,2),(@f1,@dish_fc1+2,1,3),(@f1,@dish_fc1+3,1,4),
(@f1,@dish_fc1+4,1,5),(@f1,@dish_fc1+5,1,6),(@f1,@dish_fc1+6,1,7),(@f1,@dish_fc1+7,1,8);
-- FUS8001 商务
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f1,@dish_fc1+8,2,1),(@f1,@dish_fc1+9,2,2),(@f1,@dish_fc1+10,2,3),(@f1,@dish_fc1+11,2,4),
(@f1,@dish_fc1+12,2,5),(@f1,@dish_fc1+13,2,6),(@f1,@dish_fc1+14,2,7),(@f1,@dish_fc1+15,2,8);
-- FUS8001 经济
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f1,@dish_fc1+16,3,1),(@f1,@dish_fc1+17,3,2),(@f1,@dish_fc1+18,3,3),(@f1,@dish_fc1+19,3,4),
(@f1,@dish_fc1+20,3,5),(@f1,@dish_fc1+21,3,6),(@f1,@dish_fc1+22,3,7),(@f1,@dish_fc1+23,3,8),
(@f1,@dish_fc1+24,3,9),(@f1,@dish_fc1+25,3,10);

-- FUS8002
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f2,@dish_fc1,1,1),(@f2,@dish_fc1+2,1,2),(@f2,@dish_fc1+4,1,3),(@f2,@dish_fc1+6,1,4),(@f2,@dish_fc1+7,1,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f2,@dish_fc1+8,2,1),(@f2,@dish_fc1+10,2,2),(@f2,@dish_fc1+12,2,3),(@f2,@dish_fc1+13,2,4),(@f2,@dish_fc1+15,2,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f2,@dish_fc1+16,3,1),(@f2,@dish_fc1+17,3,2),(@f2,@dish_fc1+19,3,3),(@f2,@dish_fc1+20,3,4),
(@f2,@dish_fc1+21,3,5),(@f2,@dish_fc1+22,3,6),(@f2,@dish_fc1+24,3,7),(@f2,@dish_fc1+25,3,8);

-- FUS8003
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f3,@dish_fc1+1,1,1),(@f3,@dish_fc1+3,1,2),(@f3,@dish_fc1+5,1,3),(@f3,@dish_fc1+6,1,4),(@f3,@dish_fc1+7,1,5),(@f3,@dish_fc1,1,6);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f3,@dish_fc1+9,2,1),(@f3,@dish_fc1+11,2,2),(@f3,@dish_fc1+14,2,3),(@f3,@dish_fc1+15,2,4),(@f3,@dish_fc1+8,2,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f3,@dish_fc1+16,3,1),(@f3,@dish_fc1+18,3,2),(@f3,@dish_fc1+20,3,3),(@f3,@dish_fc1+23,3,4),
(@f3,@dish_fc1+24,3,5),(@f3,@dish_fc1+25,3,6);

-- FUS8004
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f4,@dish_fc1,1,1),(@f4,@dish_fc1+2,1,2),(@f4,@dish_fc1+4,1,3),(@f4,@dish_fc1+5,1,4),(@f4,@dish_fc1+7,1,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f4,@dish_fc1+10,2,1),(@f4,@dish_fc1+12,2,2),(@f4,@dish_fc1+13,2,3),(@f4,@dish_fc1+14,2,4),(@f4,@dish_fc1+15,2,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f4,@dish_fc1+17,3,1),(@f4,@dish_fc1+19,3,2),(@f4,@dish_fc1+21,3,3),(@f4,@dish_fc1+22,3,4),
(@f4,@dish_fc1+23,3,5),(@f4,@dish_fc1+25,3,6),(@f4,@dish_fc1+16,3,7);

-- FUS8005
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f5,@dish_fc1+1,1,1),(@f5,@dish_fc1+3,1,2),(@f5,@dish_fc1+6,1,3),(@f5,@dish_fc1+7,1,4);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f5,@dish_fc1+9,2,1),(@f5,@dish_fc1+11,2,2),(@f5,@dish_fc1+13,2,3),(@f5,@dish_fc1+14,2,4);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f5,@dish_fc1+18,3,1),(@f5,@dish_fc1+20,3,2),(@f5,@dish_fc1+22,3,3),(@f5,@dish_fc1+24,3,4),(@f5,@dish_fc1+25,3,5);

-- FUS8006
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f6,@dish_fc1+2,1,1),(@f6,@dish_fc1+4,1,2),(@f6,@dish_fc1+5,1,3),(@f6,@dish_fc1+7,1,4);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f6,@dish_fc1+8,2,1),(@f6,@dish_fc1+12,2,2),(@f6,@dish_fc1+13,2,3),(@f6,@dish_fc1+15,2,4);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f6,@dish_fc1+16,3,1),(@f6,@dish_fc1+17,3,2),(@f6,@dish_fc1+19,3,3),(@f6,@dish_fc1+21,3,4),
(@f6,@dish_fc1+23,3,5),(@f6,@dish_fc1+24,3,6);

-- ============================================================
-- 5. 用户：头等舱12 + 商务舱24 + 经济舱84
-- ============================================================
-- 头等舱 (每个航班2人)
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time) VALUES
('wx_fc01','13800001001','张总裁','110101199001010001',1,@f1,1,1,'[2]','["高蛋白","咸香"]',NOW()),
('wx_fc02','13800001002','李董事长','110101199002020002',1,@f1,0,1,'[2]','["高蛋白","清淡"]',NOW()),
('wx_fc03','13800001003','王总','310101199003030003',1,@f2,1,1,'[2]','["咸香","微辣"]',NOW()),
('wx_fc04','13800001004','赵董','310101199004040004',1,@f2,0,1,'[2,3]','["高蛋白"]',NOW()),
('wx_fc05','13800001005','陈CEO','440101199005050005',1,@f3,1,1,'[2]','["咸香","甜口"]',NOW()),
('wx_fc06','13800001006','刘总','440101199006060006',1,@f3,0,1,'[2,4]','["高蛋白","低脂"]',NOW()),
('wx_fc07','13800001007','周先生','510101199007070007',1,@f4,1,1,'[2]','["清淡","高蛋白"]',NOW()),
('wx_fc08','13800001008','吴女士','510101199008080008',1,@f4,0,1,'[2,4]','["低脂","清淡"]',NOW()),
('wx_fc09','13800001009','郑总','330101199009090009',1,@f5,1,1,'[2,3]','["咸香"]',NOW()),
('wx_fc10','13800001010','孙董','330101199010100010',1,@f5,0,1,'[2]','["高蛋白","微辣"]',NOW()),
('wx_fc11','13800001011','钱CEO','460101199011110011',1,@f6,1,1,'[2]','["咸香","甜口"]',NOW()),
('wx_fc12','13800001012','马总裁','460101199012120012',1,@f6,0,1,'[2,3]','["高蛋白"]',NOW());

-- 商务舱 (每个航班4人)
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time) VALUES
('wx_bc01','13900002001','杨经理','110102199101010101',1,@f1,1,2,'[2]','["咸香","微辣"]',NOW()),
('wx_bc02','13900002002','黄主管','110102199102020202',1,@f1,0,2,'[2,4]','["清淡","低脂"]',NOW()),
('wx_bc03','13900002003','许总监','110102199103030303',1,@f1,1,2,'[2]','["甜口","咸香"]',NOW()),
('wx_bc04','13900002004','何总助','110102199104040404',1,@f1,0,2,'[2,3]','["微辣"]',NOW()),
('wx_bc05','13900002005','吕副总','310102199105050505',1,@f2,1,2,'[2]','["高蛋白","清淡"]',NOW()),
('wx_bc06','13900002006','施经理','310102199106060606',1,@f2,0,2,'[2]','["咸香"]',NOW()),
('wx_bc07','13900002007','张总监','310102199107070707',0,@f2,1,2,NULL,NULL,NOW()),
('wx_bc08','13900002008','孔主管','310102199108080808',1,@f2,0,2,'[2,4]','["低脂"]',NOW()),
('wx_bc09','13900002009','曹经理','440102199109090909',1,@f3,1,2,'[2]','["微辣","咸香"]',NOW()),
('wx_bc10','13900002010','严总监','440102199110101010',1,@f3,0,2,'[2]','["甜口"]',NOW()),
('wx_bc11','13900002011','华主管','440102199111111111',0,@f3,1,2,NULL,NULL,NOW()),
('wx_bc12','13900002012','金经理','440102199112121212',1,@f3,0,2,'[2,3]','["咸香","高蛋白"]',NOW()),
('wx_bc13','13900002013','魏总助','510102199201010101',1,@f4,1,2,'[2]','["清淡","低脂"]',NOW()),
('wx_bc14','13900002014','陶总监','510102199202020202',1,@f4,0,2,'[2]','["微辣"]',NOW()),
('wx_bc15','13900002015','姜经理','510102199203030303',0,@f4,1,2,NULL,NULL,NOW()),
('wx_bc16','13900002016','戚主管','510102199204040404',1,@f4,0,2,'[2,4]','["低脂","清淡"]',NOW()),
('wx_bc17','13900002017','谢副总','330102199205050505',1,@f5,1,2,'[2]','["咸香","甜口"]',NOW()),
('wx_bc18','13900002018','邹总监','330102199206060606',1,@f5,0,2,'[2]','["高蛋白"]',NOW()),
('wx_bc19','13900002019','喻经理','330102199207070707',1,@f5,1,2,'[2,3]','["微辣","咸香"]',NOW()),
('wx_bc20','13900002020','柏主管','330102199208080808',1,@f5,0,2,'[2,4]','["清淡"]',NOW()),
('wx_bc21','13900002021','水总助','460102199209090909',1,@f6,1,2,'[2]','["咸香"]',NOW()),
('wx_bc22','13900002022','窦经理','460102199210101010',0,@f6,0,2,NULL,NULL,NOW()),
('wx_bc23','13900002023','章总监','460102199211111111',1,@f6,1,2,'[2]','["甜口","高蛋白"]',NOW()),
('wx_bc24','13900002024','苏主管','460102199212121212',1,@f6,0,2,'[2,4]','["低脂"]',NOW());

-- 经济舱 (每个航班14人，批量生成)
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time)
SELECT CONCAT('wx_ec', LPAD(n, 4, '0')),
       CONCAT('136', LPAD(10000000 + n, 8, '0')),
       CONCAT('旅客', n),
       CONCAT('330', LPAD(n, 6, '0'), '2020010100', LPAD(n MOD 99, 2, '0')),
       IF(n <= 70, 1, 0),
       CASE (n-1) DIV 14 WHEN 0 THEN @f1 WHEN 1 THEN @f2 WHEN 2 THEN @f3 WHEN 3 THEN @f4 WHEN 4 THEN @f5 ELSE @f6 END,
       CASE n MOD 3 WHEN 0 THEN 1 WHEN 1 THEN 0 ELSE 1 END,
       3,
       IF(n <= 70, CASE n MOD 4 WHEN 0 THEN '[2]' WHEN 1 THEN '[2,3]' WHEN 2 THEN '[2,4]' ELSE '[3,4]' END, NULL),
       IF(n <= 70, CASE n MOD 6 WHEN 0 THEN '["咸香","微辣"]' WHEN 1 THEN '["清淡","低脂"]' WHEN 2 THEN '["甜口","咸香"]' WHEN 3 THEN '["高蛋白","清淡"]' WHEN 4 THEN '["微辣"]' ELSE '["清淡","低脂","高蛋白"]' END, NULL),
       DATE_ADD(NOW(), INTERVAL -n HOUR)
FROM (SELECT @row := @row + 1 AS n FROM information_schema.columns a, information_schema.columns b, (SELECT @row := 0) r LIMIT 84) t;

-- ============================================================
-- 6. 推荐日志 + 预选记录
-- ============================================================
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', CAST(@dish_fc1 + FLOOR(RAND()*8) AS CHAR), ',', CAST(@dish_fc1 + FLOOR(RAND()*8) AS CHAR), ',', CAST(@dish_fc1 + FLOOR(RAND()*8) AS CHAR), ',', CAST(@dish_fc1 + FLOOR(RAND()*8) AS CHAR), ']'),
       5,
       CONCAT('MANUAL_SELECTED:dishId=', CAST(@dish_fc1 + FLOOR(RAND()*8) AS CHAR), ':mealOrder=1'),
       DATE_ADD('2026-05-14 08:00:00', INTERVAL u.id * 30 MINUTE)
FROM user u WHERE u.cabin_type = 1 AND u.current_flight_id IS NOT NULL AND u.preference_completed = 1;

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', CAST(@dish_fc1+8 + FLOOR(RAND()*8) AS CHAR), ',', CAST(@dish_fc1+8 + FLOOR(RAND()*8) AS CHAR), ',', CAST(@dish_fc1+8 + FLOOR(RAND()*8) AS CHAR), ',', CAST(@dish_fc1+8 + FLOOR(RAND()*8) AS CHAR), ']'),
       FLOOR(3 + RAND() * 3),
       CONCAT('MANUAL_SELECTED:dishId=', CAST(@dish_fc1+8 + FLOOR(RAND()*8) AS CHAR), ':mealOrder=1'),
       DATE_ADD('2026-05-14 09:00:00', INTERVAL u.id * 20 MINUTE)
FROM user u WHERE u.cabin_type = 2 AND u.current_flight_id IS NOT NULL AND u.preference_completed = 1;

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', CAST(@dish_fc1+16 + FLOOR(RAND()*10) AS CHAR), ',', CAST(@dish_fc1+16 + FLOOR(RAND()*10) AS CHAR), ',', CAST(@dish_fc1+16 + FLOOR(RAND()*10) AS CHAR), ',', CAST(@dish_fc1+16 + FLOOR(RAND()*10) AS CHAR), ']'),
       FLOOR(1 + RAND() * 5),
       CONCAT('MANUAL_SELECTED:dishId=', CAST(@dish_fc1+16 + FLOOR(RAND()*10) AS CHAR), ':mealOrder=1'),
       DATE_ADD('2026-05-14 10:00:00', INTERVAL u.id * 15 MINUTE)
FROM user u WHERE u.cabin_type = 3 AND u.current_flight_id IS NOT NULL AND u.preference_completed = 1;

INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[', CAST(@dish_fc1 + FLOOR(RAND()*26) AS CHAR), ']'),
       CONCAT('CLICK:dishId=', CAST(@dish_fc1 + FLOOR(RAND()*26) AS CHAR), ':mealOrder=1'),
       DATE_ADD('2026-05-14 08:00:00', INTERVAL u.id * 11 MINUTE)
FROM user u WHERE u.current_flight_id IS NOT NULL AND u.preference_completed = 1 LIMIT 300;

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, create_time, update_time)
SELECT CONCAT('SEL', UNIX_TIMESTAMP(NOW()), u.id, FLOOR(RAND()*100)),
       3, u.id, u.current_flight_id, 1, NOW(), NOW()
FROM user u
WHERE u.current_flight_id IS NOT NULL
  AND u.preference_completed = 1
  AND NOT EXISTS (SELECT 1 FROM meal_selection ms WHERE ms.user_id = u.id AND ms.flight_id = u.current_flight_id AND ms.meal_order = 1)
LIMIT 80;

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, create_time, update_time)
SELECT CONCAT('SEL', UNIX_TIMESTAMP(NOW()), u.id, FLOOR(RAND()*100)),
       3, u.id, u.current_flight_id, 2, NOW(), NOW()
FROM user u
INNER JOIN flight_info fi ON fi.id = u.current_flight_id
WHERE u.preference_completed = 1
  AND fi.meal_count >= 2
  AND NOT EXISTS (SELECT 1 FROM meal_selection ms WHERE ms.user_id = u.id AND ms.flight_id = u.current_flight_id AND ms.meal_order = 2)
LIMIT 40;

-- ============================================================
-- 7. 统计
-- ============================================================
SELECT '菜品' AS 项, COUNT(*) AS 数量 FROM dish
UNION ALL SELECT '头等舱菜品', COUNT(*) FROM dish WHERE name LIKE '%菲力%' OR name LIKE '%鹅肝%' OR name LIKE '%龙虾%' OR name LIKE '%刺身%' OR name LIKE '%三文鱼%' OR name LIKE '%松露%' OR name LIKE '%羊排%' OR name LIKE '%鱼子酱%'
UNION ALL SELECT '商务舱菜品', COUNT(*) FROM dish WHERE name LIKE '%宫保虾球%' OR name LIKE '%鲍鱼%' OR name LIKE '%黑椒牛柳%' OR name LIKE '%咖喱鸡肉%' OR name LIKE '%银鳕鱼%' OR name LIKE '%叉烧%' OR name LIKE '%XO酱%' OR name LIKE '%照烧%'
UNION ALL SELECT '经济舱菜品', COUNT(*) FROM dish WHERE name LIKE '%红烧牛肉面%' OR name LIKE '%宫保鸡丁盖饭%' OR name LIKE '%番茄鸡蛋%' OR name LIKE '%鱼香肉丝%' OR name LIKE '%回锅肉%' OR name LIKE '%香菇滑鸡%' OR name LIKE '%麻婆豆腐%' OR name LIKE '%清炒时蔬%' OR name LIKE '%鸡蛋三明治%' OR name LIKE '%什锦炒饭%'
UNION ALL SELECT '航班', COUNT(*) FROM flight_info WHERE flight_number LIKE 'FUS8%'
UNION ALL SELECT '航线绑定', COUNT(*) FROM flight_dish WHERE flight_id IN (SELECT id FROM flight_info WHERE flight_number LIKE 'FUS8%')
UNION ALL SELECT '头等绑定', COUNT(*) FROM flight_dish WHERE cabin_type=1 AND flight_id IN (SELECT id FROM flight_info WHERE flight_number LIKE 'FUS8%')
UNION ALL SELECT '商务绑定', COUNT(*) FROM flight_dish WHERE cabin_type=2 AND flight_id IN (SELECT id FROM flight_info WHERE flight_number LIKE 'FUS8%')
UNION ALL SELECT '经济绑定', COUNT(*) FROM flight_dish WHERE cabin_type=3 AND flight_id IN (SELECT id FROM flight_info WHERE flight_number LIKE 'FUS8%')
UNION ALL SELECT '用户总数', COUNT(*) FROM user WHERE openid LIKE 'wx_fc%' OR openid LIKE 'wx_bc%' OR openid LIKE 'wx_ec%'
UNION ALL SELECT '头等舱用户', COUNT(*) FROM user WHERE cabin_type=1 AND openid LIKE 'wx_fc%'
UNION ALL SELECT '商务舱用户', COUNT(*) FROM user WHERE cabin_type=2 AND openid LIKE 'wx_bc%'
UNION ALL SELECT '经济舱用户', COUNT(*) FROM user WHERE cabin_type=3 AND openid LIKE 'wx_ec%'
UNION ALL SELECT '推荐日志', COUNT(*) FROM recommendation_log;
