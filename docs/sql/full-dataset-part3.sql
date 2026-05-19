-- ============================================================
-- Part 3: 用户 + 日志 + 预选 + 评分 + 公告
-- ============================================================
USE aviation_food_recommend;

SET @fc_start = (SELECT MIN(id) FROM dish WHERE name LIKE '%澳洲M9%');
SET @f1 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8001');
SET @f2 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8002');
SET @f3 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8003');
SET @f4 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8004');
SET @f5 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8005');
SET @f6 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8006');
SET @f7 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8007');
SET @f8 = (SELECT id FROM flight_info WHERE flight_number = 'FUS8008');

-- ============================================================
-- 6. 演示用户：胡屿科 头等舱 FUS8001
-- ============================================================
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time) VALUES
('wx_demo_hyk','18080099833','胡屿科','510411200309180910',1,@f1,1,1,'[2]','["咸香","高蛋白","微辣"]','2026-05-10 08:00:00');
SET @demo_uid = LAST_INSERT_ID();

-- 头等舱 (其余11人)
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time) VALUES
('wx_fc02','13800001002','张总裁','110101199001010001',1,@f1,1,1,'[2]','["高蛋白","咸香"]','2026-05-10 09:00:00'),
('wx_fc03','13800001003','李董事长','110101199002020002',1,@f2,0,1,'[2]','["清淡","高蛋白"]','2026-05-10 09:10:00'),
('wx_fc04','13800001004','王总','310101199003030003',1,@f2,1,1,'[2,3]','["咸香","微辣"]','2026-05-10 09:20:00'),
('wx_fc05','13800001005','赵董','310101199004040004',1,@f3,0,1,'[2]','["高蛋白","低脂"]','2026-05-10 09:30:00'),
('wx_fc06','13800001006','陈CEO','440101199005050005',1,@f3,1,1,'[2,4]','["咸香","甜口"]','2026-05-10 09:40:00'),
('wx_fc07','13800001007','刘总','440101199006060006',1,@f4,0,1,'[2]','["高蛋白","清淡"]','2026-05-10 09:50:00'),
('wx_fc08','13800001008','周先生','510101199007070007',1,@f4,1,1,'[2]','["咸香","微辣"]','2026-05-10 10:00:00'),
('wx_fc09','13800001009','吴女士','510101199008080008',1,@f5,0,1,'[2,4]','["低脂","清淡"]','2026-05-10 10:10:00'),
('wx_fc10','13800001010','郑总','330101199009090009',1,@f6,1,1,'[2]','["咸香","高蛋白"]','2026-05-10 10:20:00'),
('wx_fc11','13800001011','孙董','330101199010100010',1,@f7,0,1,'[2,3]','["微辣","咸香"]','2026-05-10 10:30:00'),
('wx_fc12','13800001012','钱总','460101199011110011',1,@f8,1,1,'[2]','["高蛋白","甜口"]','2026-05-10 10:40:00');

-- 商务舱 (30人)
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time)
SELECT CONCAT('wx_bc', LPAD(n, 2, '0')),
       CONCAT('139', LPAD(10000000 + n, 8, '0')),
       ELT(1+(n-1)%10, '杨经理','黄主管','许总监','何总助','吕副总','施经理','张总监','孔主管','曹经理','严总监'),
       CONCAT('110', LPAD(100000 + n, 6, '0'), '1990010100', LPAD(n, 2, '0')),
       IF(n <= 27, 1, 0),
       ELT(1+(n-1)%8, @f1,@f2,@f3,@f4,@f5,@f6,@f7,@f8),
       IF(n MOD 2 = 0, 0, 1), 2,
       IF(n <= 27, ELT(1+(n-1)%4, '[2]','[2,3]','[2,4]','[2]'), NULL),
       IF(n <= 27, ELT(1+(n-1)%5, '["咸香","微辣"]','["清淡","低脂"]','["甜口","咸香"]','["高蛋白"]','["微辣"]'), NULL),
       DATE_ADD('2026-05-10', INTERVAL n HOUR)
FROM (SELECT @row := @row + 1 AS n FROM information_schema.columns a, information_schema.columns b, (SELECT @row := 0) r LIMIT 30) t;

-- 经济舱 (78人)
INSERT INTO user (openid, phone, name, id_number, preference_completed, current_flight_id, gender, cabin_type, meal_type_preferences, flavor_preferences, create_time)
SELECT CONCAT('wx_ec', LPAD(n, 3, '0')),
       CONCAT('136', LPAD(10000000 + n, 8, '0')),
       CONCAT('旅客', n),
       CONCAT('330', LPAD(n, 6, '0'), '2020010100', LPAD(n MOD 99, 2, '0')),
       IF(n <= 68, 1, 0),
       ELT(1+(n-1)%8, @f1,@f2,@f3,@f4,@f5,@f6,@f7,@f8),
       CASE n MOD 3 WHEN 0 THEN 1 WHEN 1 THEN 0 ELSE 1 END, 3,
       IF(n <= 68, ELT(1+n MOD 4, '[2]','[2,3]','[2,4]','[3,4]'), NULL),
       IF(n <= 68, ELT(1+n MOD 6, '["咸香","微辣"]','["清淡","低脂"]','["甜口","咸香"]','["高蛋白","清淡"]','["微辣"]','["清淡","低脂","高蛋白"]'), NULL),
       DATE_ADD('2026-05-10', INTERVAL n*10 MINUTE)
FROM (SELECT @row2 := @row2 + 1 AS n FROM information_schema.columns a, information_schema.columns b, (SELECT @row2 := 0) r LIMIT 78) t;

-- ============================================================
-- 7. 推荐日志 (500+)
-- ============================================================

-- 胡屿科专属日志
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time) VALUES
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]',5,'MANUAL_SELECTED:dishId=1:mealOrder=1','2026-05-12 08:30:00'),
(@demo_uid,@f2,'[1,3,5,7,9,11,13,15]',5,'MANUAL_SELECTED:dishId=3:mealOrder=1','2026-05-08 09:00:00'),
(@demo_uid,@f2,'[2,4,6,8,10,12,14,16]',4,'MANUAL_SELECTED:dishId=1:mealOrder=2','2026-05-08 11:30:00');
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, create_time) VALUES
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=1:mealOrder=1','2026-05-12 08:00:00'),
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=2:mealOrder=1','2026-05-12 08:02:00'),
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=5:mealOrder=1','2026-05-12 08:05:00'),
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=1:mealOrder=1','2026-05-14 09:00:00'),
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=3:mealOrder=1','2026-05-14 09:03:00'),
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=1:mealOrder=1','2026-05-15 07:00:00'),
(@demo_uid,@f1,'[1,2,3,4,5,6,7,8]','CLICK:dishId=4:mealOrder=1','2026-05-15 07:02:00');

-- 头等舱用户选餐日志
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@fc_start,',',@fc_start+1,',',@fc_start+2,',',@fc_start+3,',',@fc_start+4,',',@fc_start+5,',',@fc_start+6,',',@fc_start+7,']'),
       5, CONCAT('MANUAL_SELECTED:dishId=',@fc_start+FLOOR(RAND()*8),':mealOrder=1'),
       DATE_ADD('2026-05-12', INTERVAL u.id HOUR)
FROM user u WHERE u.cabin_type = 1 AND u.id != @demo_uid AND u.preference_completed = 1;

-- 商务舱用户选餐日志
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@fc_start+18,',',@fc_start+19,',',@fc_start+20,',',@fc_start+21,',',@fc_start+22,',',@fc_start+23,',',@fc_start+24,',',@fc_start+25,']'),
       FLOOR(3+RAND()*3), CONCAT('MANUAL_SELECTED:dishId=',@fc_start+18+FLOOR(RAND()*18),':mealOrder=1'),
       DATE_ADD('2026-05-12', INTERVAL u.id MINUTE)
FROM user u WHERE u.cabin_type = 2 AND u.preference_completed = 1;

-- 经济舱用户选餐日志 (跨批次覆盖)
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_rating, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@fc_start+36,',',@fc_start+37,',',@fc_start+38,',',@fc_start+39,',',@fc_start+40,',',@fc_start+41,',',@fc_start+42,',',@fc_start+43,']'),
       FLOOR(1+RAND()*5), CONCAT('MANUAL_SELECTED:dishId=',@fc_start+36+FLOOR(RAND()*20),':mealOrder=1'),
       DATE_ADD('2026-05-12', INTERVAL u.id*3 MINUTE)
FROM user u WHERE u.cabin_type = 3 AND u.preference_completed = 1 AND u.id MOD 2 = 0;

-- 批量CLICK日志 (填充500+)
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, create_time)
SELECT u.id, u.current_flight_id,
       CONCAT('[',@fc_start + FLOOR(RAND()*56), ',', @fc_start + FLOOR(RAND()*56), ',', @fc_start + FLOOR(RAND()*56), ']'),
       CONCAT('CLICK:dishId=', @fc_start + FLOOR(RAND()*56), ':mealOrder=', IF(fi.meal_count>=2 AND RAND()>0.5, 2, 1)),
       DATE_ADD('2026-05-10', INTERVAL u.id*7 + FLOOR(RAND()*200) MINUTE)
FROM user u INNER JOIN flight_info fi ON fi.id = u.current_flight_id
WHERE u.preference_completed = 1 LIMIT 400;

-- ============================================================
-- 8. 餐食预选
-- ============================================================
INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, create_time, update_time)
SELECT CONCAT('SEL', UNIX_TIMESTAMP(NOW()), u.id, FLOOR(RAND()*1000)),
       3, u.id, u.current_flight_id, 1,
       DATE_ADD('2026-05-12', INTERVAL u.id MINUTE), NOW()
FROM user u WHERE u.current_flight_id IS NOT NULL AND u.preference_completed = 1
AND NOT EXISTS (SELECT 1 FROM meal_selection ms WHERE ms.user_id = u.id AND ms.flight_id = u.current_flight_id AND ms.meal_order = 1)
LIMIT 90;

INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, create_time, update_time)
SELECT CONCAT('SEL', UNIX_TIMESTAMP(NOW()), u.id, FLOOR(RAND()*1000)),
       3, u.id, u.current_flight_id, 2,
       DATE_ADD('2026-05-12', INTERVAL u.id+30 MINUTE), NOW()
FROM user u INNER JOIN flight_info fi ON fi.id = u.current_flight_id
WHERE u.preference_completed = 1 AND fi.meal_count >= 2
AND NOT EXISTS (SELECT 1 FROM meal_selection ms WHERE ms.user_id = u.id AND ms.flight_id = u.current_flight_id AND ms.meal_order = 2)
LIMIT 45;

-- ============================================================
-- 9. 评分任务
-- ============================================================
INSERT INTO flight_service_rating (user_id, flight_id, rating_score, rating_status, first_visible_at, expire_at, create_time, update_time)
SELECT u.id, u.current_flight_id,
       FLOOR(3+RAND()*3), 'SUBMITTED',
       DATE_ADD('2026-05-12', INTERVAL u.id HOUR),
       DATE_ADD('2026-05-19', INTERVAL u.id HOUR),
       DATE_ADD('2026-05-12', INTERVAL u.id HOUR), NOW()
FROM user u WHERE u.preference_completed = 1 AND u.id MOD 3 = 0 LIMIT 30;

INSERT INTO flight_service_rating (user_id, flight_id, rating_status, first_visible_at, expire_at, create_time, update_time)
SELECT u.id, u.current_flight_id,
       'PENDING', NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), NOW(), NOW()
FROM user u WHERE u.preference_completed = 1 AND u.id MOD 5 = 0
AND NOT EXISTS (SELECT 1 FROM flight_service_rating fsr WHERE fsr.user_id = u.id AND fsr.flight_id = u.current_flight_id)
LIMIT 15;

-- ============================================================
-- 10. 航班公告
-- ============================================================
INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time) VALUES
(@f1,'餐食预选已开放','尊敬的旅客，FUS8001航班餐食预选现已开放，请在截止时间前完成预选。',1,1,NOW()),
(@f2,'预选截止提醒','FUS8002航班预选将在24小时后截止，请尽快完成您的餐食选择。',1,1,NOW()),
(@f3,'餐食调整通知','因食材供应原因，部分菜品已做调整，请重新查看菜单。',1,1,NOW()),
(@f6,'欢迎选乘','FUS8006航班现已开放餐食预选，祝您旅途愉快！',1,1,NOW());

-- ============================================================
-- 11. 统计
-- ============================================================
SELECT '===== 数据集汇总 =====' AS '';
SELECT 'DISH', COUNT(*) FROM dish
UNION ALL SELECT 'EMPLOYEE', COUNT(*) FROM employee
UNION ALL SELECT 'CATEGORY', COUNT(*) FROM category
UNION ALL SELECT 'FLIGHT_INFO', COUNT(*) FROM flight_info
UNION ALL SELECT 'FLIGHT_DISH', COUNT(*) FROM flight_dish
UNION ALL SELECT 'USER', COUNT(*) FROM user
UNION ALL SELECT '  ->头等舱', COUNT(*) FROM user WHERE cabin_type=1
UNION ALL SELECT '  ->商务舱', COUNT(*) FROM user WHERE cabin_type=2
UNION ALL SELECT '  ->经济舱', COUNT(*) FROM user WHERE cabin_type=3
UNION ALL SELECT 'RECOMMENDATION_LOG', COUNT(*) FROM recommendation_log
UNION ALL SELECT 'MEAL_SELECTION', COUNT(*) FROM meal_selection
UNION ALL SELECT 'FLIGHT_RATING', COUNT(*) FROM flight_service_rating
UNION ALL SELECT 'ANNOUNCEMENT', COUNT(*) FROM flight_announcement;

SELECT '===== 演示用户 胡屿科 =====' AS '';
SELECT id, name, id_number, cabin_type,
       (SELECT flight_number FROM flight_info WHERE id = current_flight_id) AS flight
FROM user WHERE openid = 'wx_demo_hyk';
