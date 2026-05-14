-- ============================================================
-- 航空旅客智能美食推荐系统 —— 综合测试数据集
-- 覆盖：冷启动、正常推荐、口味漂移、多餐食、舱位差异化、
--        超时自动分配、评分生命周期、自适应权重验证
-- ============================================================

USE aviation_food_recommend;
SET FOREIGN_KEY_CHECKS = 0;

-- ===== 1. 管理员（2人） =====
INSERT INTO employee (id, account, username, name, password, phone, gender, status, create_time, update_time) VALUES
(1, 'admin',    'admin',    '系统管理员', 'e10adc3949ba59abbe56e057f20f883e', '13800000001', 1, 1, NOW(), NOW()),
(2, 'operator', 'operator', '运营人员',   'e10adc3949ba59abbe56e057f20f883e', '13800000002', 1, 1, NOW(), NOW());

-- ===== 2. 分类（5类） =====
INSERT INTO category (id, type, name, sort, status, create_time, update_time) VALUES
(1, 1, '融合主餐', 1, 1, NOW(), NOW()),
(2, 1, '轻食健康', 2, 1, NOW(), NOW()),
(3, 1, '清真专区', 3, 1, NOW(), NOW()),
(4, 1, '儿童餐食', 4, 1, NOW(), NOW()),
(5, 1, '早餐系列', 5, 1, NOW(), NOW());

-- ===== 3. 菜品（30道） =====
-- mealType: 1=儿童餐, 2=标准餐, 3=清真餐, 4=素食
INSERT INTO dish (id, name, category_id, meal_type, flavor_tags, status, stock, pic, detail, create_time, update_time, create_user) VALUES
-- 融合主餐 (category=1)
(1,  '经典红烧牛腩饭',    1, 2, '["咸香","热食"]',       1, 120, NULL, '精选牛腩慢炖，搭配时蔬与米饭',       NOW(), NOW(), 1),
(2,  '川香麻辣牛肉面',    1, 2, '["微辣","咸香"]',       1, 100, NULL, '四川风味麻辣汤底，手工拉面',          NOW(), NOW(), 1),
(3,  '照烧鸡腿饭',        1, 2, '["甜口","咸香"]',       1, 110, NULL, '日式照烧酱汁鸡腿，配白米饭',          NOW(), NOW(), 1),
(4,  '黑椒牛柳炒意面',    1, 2, '["咸香","高蛋白"]',     1,  90, NULL, '黑椒牛柳配意大利面',                  NOW(), NOW(), 1),
(5,  '梅菜扣肉饭',        1, 2, '["咸香","热食"]',       1,  80, NULL, '传统梅菜扣肉，肥而不腻',              NOW(), NOW(), 1),
-- 轻食健康 (category=2)
(6,  '低脂鸡胸藜麦饭',    2, 2, '["清淡","低脂","高蛋白"]', 1, 95, NULL, '低脂鸡胸肉配超级食物藜麦',          NOW(), NOW(), 1),
(7,  '香烤鳕鱼时蔬饭',    2, 2, '["清淡","高蛋白"]',     1,  85, NULL, '香烤银鳕鱼搭配时令蔬菜',              NOW(), NOW(), 1),
(8,  '全素菌菇烩饭',      2, 4, '["清淡","低脂"]',       1,  70, NULL, '多种菌菇慢炖，素食健康之选',          NOW(), NOW(), 1),
(9,  '凯撒鸡胸沙拉',      2, 2, '["清淡","低脂","高蛋白"]', 1, 75, NULL, '经典凯撒沙拉配鸡胸肉',              NOW(), NOW(), 1),
(10, '藜麦牛油果拌饭',    2, 4, '["清淡","低脂"]',       1,  65, NULL, '藜麦配新鲜牛油果，清爽健康',          NOW(), NOW(), 1),
(11, '低温慢煮三文鱼',    2, 2, '["清淡","高蛋白"]',     1,  60, NULL, '低温慢煮保留鱼肉鲜美',                NOW(), NOW(), 1),
-- 清真专区 (category=3)
(12, '清真咖喱鸡肉饭',    3, 3, '["咸香","微辣"]',       1,  80, NULL, '清真认证咖喱鸡肉，香料丰富',          NOW(), NOW(), 1),
(13, '清真孜然羊肉饭',    3, 3, '["咸香","微辣"]',       1,  70, NULL, '清真孜然羊肉配米饭',                  NOW(), NOW(), 1),
(14, '清真番茄牛肉饭',    3, 3, '["清淡","咸香"]',       1,  75, NULL, '清真认证番茄炖牛肉',                  NOW(), NOW(), 1),
(15, '清真烤鸡腿饭',      3, 3, '["咸香","高蛋白"]',     1,  85, NULL, '清真烤鸡腿，外焦里嫩',                NOW(), NOW(), 1),
-- 儿童餐食 (category=4)
(16, '番茄儿童意面',      4, 1, '["甜口"]',             1,  60, NULL, '可爱蝴蝶面配酸甜番茄酱',              NOW(), NOW(), 1),
(17, '鸡块土豆泥套餐',    4, 1, '["清淡","咸香"]',       1,  55, NULL, '黄金鸡块配绵密土豆泥',                NOW(), NOW(), 1),
(18, '小熊饭团便当',      4, 1, '["清淡","甜口"]',       1,  50, NULL, '可爱小熊造型饭团，趣味营养',          NOW(), NOW(), 1),
(19, '迷你汉堡套餐',      4, 1, '["咸香"]',             1,  55, NULL, '儿童专属迷你汉堡配蔬菜条',            NOW(), NOW(), 1),
-- 早餐系列 (category=5)
(20, '能量火腿三明治',    5, 2, '["清淡","高蛋白"]',     1,  90, NULL, '全麦面包配火腿芝士',                  NOW(), NOW(), 1),
(21, '豆浆油条组合',      5, 2, '["清淡","热食"]',       1,  80, NULL, '现磨豆浆配酥脆油条',                  NOW(), NOW(), 1),
(22, '皮蛋瘦肉粥套餐',    5, 2, '["清淡","咸香"]',       1,  75, NULL, '熬制绵密皮蛋瘦肉粥配小菜',            NOW(), NOW(), 1),
(23, '全麦牛油果吐司',    5, 4, '["清淡","低脂"]',       1,  60, NULL, '全麦吐司配新鲜牛油果',                NOW(), NOW(), 1),
(24, '美式煎饼套餐',      5, 2, '["甜口","热食"]',       1,  70, NULL, '松软美式煎饼配枫糖浆',                NOW(), NOW(), 1),
-- 素食专项（跨分类）
(25, '素食豆腐丼',        2, 4, '["清淡","低脂","高蛋白"]', 1, 65, NULL, '手工豆腐配时蔬盖饭',                NOW(), NOW(), 1),
(26, '素食天妇罗定食',    2, 4, '["清淡","甜口"]',       1,  55, NULL, '时令蔬菜天妇罗',                      NOW(), NOW(), 1),
(27, '素食麻婆豆腐饭',    2, 4, '["微辣","咸香"]',       1,  70, NULL, '素食版麻婆豆腐，香辣可口',            NOW(), NOW(), 1),
(28, '素食佛跳墙',        2, 4, '["清淡","咸香","高蛋白"]', 1, 50, NULL, '素食版佛跳墙，菌菇荟萃',            NOW(), NOW(), 1),
-- 极端标签组合
(29, '低脂水果酸奶杯',    2, 4, '["甜口","清淡","低脂"]', 1, 100, NULL, '新鲜水果配低脂酸奶',                 NOW(), NOW(), 1),
(30, '高蛋白能量碗',      2, 2, '["高蛋白","清淡","低脂"]', 1, 60, NULL, '高蛋白谷物能量碗',                   NOW(), NOW(), 1);

-- ===== 4. 航班（10个） =====
-- 状态: 1=启用, 0=禁用; 含不同航线、餐食数量、预选截止状态
INSERT INTO flight_info (id, flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_time, update_time, create_user) VALUES
-- 活跃航班（预选开放中）
(1, 'FUS6101', '上海浦东', '成都双流',   '2026-05-16 08:00:00', '2026-05-16 11:00:00', 180, 2, '2026-05-15 20:00:00', 1, NOW(), NOW(), 1),
(2, 'FUS6202', '北京首都', '深圳宝安',   '2026-05-16 14:00:00', '2026-05-16 17:30:00', 210, 2, '2026-05-16 06:00:00', 1, NOW(), NOW(), 1),
(3, 'FUS6303', '广州白云', '乌鲁木齐',   '2026-05-17 09:00:00', '2026-05-17 14:00:00', 300, 2, '2026-05-16 21:00:00', 1, NOW(), NOW(), 1),
-- 预选截止即将到来（用于测试自动分配）
(4, 'FUS6404', '杭州萧山', '西安咸阳',   '2026-05-16 08:30:00', '2026-05-16 11:00:00', 150, 1, DATE_SUB(NOW(), INTERVAL 1 HOUR), 1, NOW(), NOW(), 1),
-- 已到达航班（可用于评分）
(5, 'FUS6505', '成都双流', '北京首都',   '2026-05-14 10:00:00', '2026-05-14 13:00:00', 180, 2, '2026-05-13 22:00:00', 1, NOW(), NOW(), 1),
(6, 'FUS6606', '深圳宝安', '上海浦东',   '2026-05-14 15:00:00', '2026-05-14 18:00:00', 180, 1, '2026-05-14 07:00:00', 1, NOW(), NOW(), 1),
-- 历史航班（用于测试长期行为信号衰减）
(7, 'FUS6707', '昆明长水', '杭州萧山',   '2026-05-01 07:00:00', '2026-05-01 10:00:00', 180, 1, '2026-04-30 19:00:00', 1, NOW(), NOW(), 1),
(8, 'FUS6808', '重庆江北', '广州白云',   '2026-04-25 12:00:00', '2026-04-25 14:30:00', 150, 1, '2026-04-25 04:00:00', 1, NOW(), NOW(), 1),
-- 不同航线的丰富航班
(9, 'FUS6909', '西安咸阳', '昆明长水',   '2026-05-17 16:00:00', '2026-05-17 19:00:00', 180, 1, '2026-05-17 08:00:00', 1, NOW(), NOW(), 1),
(10,'FUS7010', '乌鲁木齐', '上海浦东',   '2026-05-18 06:00:00', '2026-05-18 10:00:00', 240, 2, '2026-05-17 18:00:00', 1, NOW(), NOW(), 1);

-- ===== 5. 航班-菜品绑定（按航班+舱位配置） =====
-- cabin_type: 1=头等舱, 2=商务舱, 3=经济舱
-- FUS6101 上海→成都 (2餐)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(1, 1, 3, 1, 1), (1, 2, 3, 2, 1), (1, 3, 3, 3, 1), (1, 6, 3, 4, 1), (1, 7, 3, 5, 1), (1, 8, 3, 6, 1),  -- 经济舱 6道
(1, 29, 1, 1, 1), (1, 11, 1, 2, 1),  -- 头等舱专属 2道
(1, 9, 2, 1, 1), (1, 30, 2, 2, 1);  -- 商务舱专属 2道

-- FUS6202 北京→深圳 (2餐)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(2, 2, 3, 1, 1), (2, 4, 3, 2, 1), (2, 6, 3, 3, 1), (2, 12, 3, 4, 1), (2, 13, 3, 5, 1),  -- 经济舱 5道
(2, 7, 2, 1, 1), (2, 9, 2, 2, 1);

-- FUS6303 广州→乌鲁木齐 (2餐，长航程)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(3, 1, 3, 1, 1), (3, 2, 3, 2, 1), (3, 12, 3, 3, 1), (3, 14, 3, 4, 1), (3, 6, 3, 5, 1), (3, 10, 3, 6, 1),
(3, 25, 3, 7, 1), (3, 27, 3, 8, 1),  -- 经济舱 8道
(3, 11, 1, 1, 1), (3, 29, 1, 2, 1),  -- 头等舱 2道
(3, 30, 2, 1, 1);  -- 商务舱 1道

-- FUS6404 杭州→西安 (1餐，即将截止)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(4, 20, 3, 1, 1), (4, 21, 3, 2, 1), (4, 22, 3, 3, 1), (4, 24, 3, 4, 1);

-- FUS6505 成都→北京 (已到达，可用于评分)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(5, 1, 3, 1, 1), (5, 2, 3, 2, 1), (5, 3, 3, 3, 1), (5, 6, 3, 4, 1), (5, 7, 3, 5, 1);

-- FUS6606 深圳→上海 (已到达)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(6, 3, 3, 1, 1), (6, 4, 3, 2, 1), (6, 6, 3, 3, 1);

-- FUS6707 昆明→杭州 (历史)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(7, 6, 3, 1, 1), (7, 7, 3, 2, 1), (7, 8, 3, 3, 1), (7, 9, 3, 4, 1);

-- FUS6808 重庆→广州 (历史)
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(8, 1, 3, 1, 1), (8, 2, 3, 2, 1), (8, 12, 3, 3, 1), (8, 13, 3, 4, 1);

-- FUS6909 西安→昆明
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(9, 6, 3, 1, 1), (9, 7, 3, 2, 1), (9, 25, 3, 3, 1), (9, 26, 3, 4, 1);

-- FUS7010 乌鲁木齐→上海
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort, create_user) VALUES
(10, 12, 3, 1, 1), (10, 13, 3, 2, 1), (10, 14, 3, 3, 1), (10, 15, 3, 4, 1), (10, 6, 3, 5, 1), (10, 7, 3, 6, 1);

-- ===== 6. 用户（50人） =====
-- 舱位分布：头等舱~10%(5人)、商务舱~20%(10人)、经济舱~70%(35人)
-- 偏好完成率~90%

-- 头等舱用户 (cabin_type=1)
INSERT INTO user (id, openid, name, phone, id_number, gender, cabin_type, preference_completed, current_flight_id, meal_type_preferences, flavor_preferences, create_time, update_time) VALUES
(1,  'openid_u01', '张伟',   '13900000001', '110101199001011234', 1, 1, 1, 1, '[2]',       '["咸香","微辣"]',       DATE_SUB(NOW(), INTERVAL 90 DAY), NOW()),
(2,  'openid_u02', '李娜',   '13900000002', '110101199102022345', 0, 1, 1, 2, '[2]',       '["清淡","高蛋白"]',     DATE_SUB(NOW(), INTERVAL 85 DAY), NOW()),
(3,  'openid_u03', '王磊',   '13900000003', '110101199203033456', 1, 1, 1, 3, '[1,2]',     '["清淡","甜口"]',       DATE_SUB(NOW(), INTERVAL 80 DAY), NOW()),
(4,  'openid_u04', '赵敏',   '13900000004', '110101199304044567', 0, 1, 1, 5, '[2]',       '["咸香","高蛋白"]',     DATE_SUB(NOW(), INTERVAL 75 DAY), NOW()),
(5,  'openid_u05', '陈静',   '13900000005', '110101199405055678', 0, 1, 1, 1, '[2,4]',     '["清淡","低脂"]',       DATE_SUB(NOW(), INTERVAL 70 DAY), NOW());

-- 商务舱用户 (cabin_type=2)
INSERT INTO user (id, openid, name, phone, id_number, gender, cabin_type, preference_completed, current_flight_id, meal_type_preferences, flavor_preferences, create_time, update_time) VALUES
(6,  'openid_u06', '孙涛',   '13900000006', '120101199506066789', 1, 2, 1, 1, '[2]',       '["微辣","咸香"]',       DATE_SUB(NOW(), INTERVAL 65 DAY), NOW()),
(7,  'openid_u07', '周杰',   '13900000007', '120101199607077890', 1, 2, 1, 2, '[2,3]',     '["咸香","热食"]',       DATE_SUB(NOW(), INTERVAL 60 DAY), NOW()),
(8,  'openid_u08', '吴桐',   '13900000008', '120101199708088901', 0, 2, 1, 3, '[2]',       '["清淡","低脂"]',       DATE_SUB(NOW(), INTERVAL 55 DAY), NOW()),
(9,  'openid_u09', '郑爽',   '13900000009', '120101199809099012', 0, 2, 1, 5, '[2]',       '["高蛋白","清淡"]',     DATE_SUB(NOW(), INTERVAL 50 DAY), NOW()),
(10, 'openid_u10', '冯刚',   '13900000010', '120101199910100123', 1, 2, 1, 6, '[2]',       '["咸香","微辣"]',       DATE_SUB(NOW(), INTERVAL 45 DAY), NOW());

-- 口味漂移组用户 (cabin_type=3, 偏好咸香→微辣漂移, 编号11-20)
INSERT INTO user (id, openid, name, phone, id_number, gender, cabin_type, preference_completed, current_flight_id, meal_type_preferences, flavor_preferences, create_time, update_time) VALUES
(11, 'openid_u11', '黄明',   '13900000011', '310101200001011234', 1, 3, 1, 1, '[2]',  '["咸香","热食"]',     DATE_SUB(NOW(), INTERVAL 40 DAY), NOW()),
(12, 'openid_u12', '林红',   '13900000012', '310101200102022345', 0, 3, 1, 1, '[2]',  '["咸香","微辣"]',     DATE_SUB(NOW(), INTERVAL 38 DAY), NOW()),
(13, 'openid_u13', '何强',   '13900000013', '310101200203033456', 1, 3, 1, 3, '[2]',  '["微辣","咸香"]',     DATE_SUB(NOW(), INTERVAL 35 DAY), NOW()),
(14, 'openid_u14', '刘洋',   '13900000014', '310101200304044567', 0, 3, 1, 5, '[1]',  '["甜口","清淡"]',     DATE_SUB(NOW(), INTERVAL 32 DAY), NOW()),
(15, 'openid_u15', '马超',   '13900000015', '310101200405055678', 1, 3, 1, 1, '[2,3]','["高蛋白","清淡"]',   DATE_SUB(NOW(), INTERVAL 30 DAY), NOW()),
(16, 'openid_u16', '宋雨',   '13900000016', '310101200506066789', 0, 3, 1, 2, '[2]',  '["清淡","低脂"]',     DATE_SUB(NOW(), INTERVAL 28 DAY), NOW()),
(17, 'openid_u17', '唐磊',   '13900000017', '310101200607077890', 1, 3, 1, 8, '[2]',  '["咸香","热食"]',     DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),
(18, 'openid_u18', '韩冰',   '13900000018', '310101200708088901', 0, 3, 1, 7, '[2,4]','["清淡","低脂"]',     DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
(19, 'openid_u19', '曹阳',   '13900000019', '310101200809099012', 1, 3, 1, 1, '[2]',  '["微辣","高蛋白"]',   DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(20, 'openid_u20', '邓丽',   '13900000020', '310101200910100123', 0, 3, 1, 2, '[2]',  '["咸香","微辣"]',     DATE_SUB(NOW(), INTERVAL 10 DAY), NOW());

-- 普通经济舱用户 (cabin_type=3, 编号21-40)
INSERT INTO user (id, openid, name, phone, id_number, gender, cabin_type, preference_completed, current_flight_id, meal_type_preferences, flavor_preferences, create_time, update_time) VALUES
(21, 'openid_u21', '彭飞',   '13900000021', '410101200001011234', 1, 3, 1, 1, '[2]',    '["咸香","微辣"]',       DATE_SUB(NOW(), INTERVAL 30 DAY), NOW()),
(22, 'openid_u22', '董洁',   '13900000022', '410101200102022345', 0, 3, 1, 2, '[2]',    '["清淡","高蛋白"]',     DATE_SUB(NOW(), INTERVAL 29 DAY), NOW()),
(23, 'openid_u23', '苏瑞',   '13900000023', '410101200203033456', 1, 3, 1, 3, '[3]',    '["咸香"]',             DATE_SUB(NOW(), INTERVAL 28 DAY), NOW()),
(24, 'openid_u24', '蒋文',   '13900000024', '410101200304044567', 0, 3, 1, 5, '[2,4]',  '["清淡","低脂"]',       DATE_SUB(NOW(), INTERVAL 27 DAY), NOW()),
(25, 'openid_u25', '沈明',   '13900000025', '410101200405055678', 1, 3, 1, 6, '[2]',    '["咸香","热食"]',       DATE_SUB(NOW(), INTERVAL 26 DAY), NOW()),
(26, 'openid_u26', '韩雪',   '13900000026', '410101200506066789', 0, 3, 1, 7, '[2]',    '["微辣","咸香"]',       DATE_SUB(NOW(), INTERVAL 25 DAY), NOW()),
(27, 'openid_u27', '魏晨',   '13900000027', '410101200607077890', 1, 3, 1, 8, '[2]',    '["清淡","甜口"]',       DATE_SUB(NOW(), INTERVAL 24 DAY), NOW()),
(28, 'openid_u28', '田蜜',   '13900000028', '410101200708088901', 0, 3, 1, 1, '[1]',    '["甜口"]',             DATE_SUB(NOW(), INTERVAL 23 DAY), NOW()),
(29, 'openid_u29', '潘龙',   '13900000029', '410101200809099012', 1, 3, 1, 2, '[2,3]',  '["高蛋白","咸香"]',     DATE_SUB(NOW(), INTERVAL 22 DAY), NOW()),
(30, 'openid_u30', '尤佳',   '13900000030', '410101200910100123', 0, 3, 1, 3, '[4]',    '["清淡","低脂"]',       DATE_SUB(NOW(), INTERVAL 21 DAY), NOW()),
(31, 'openid_u31', '许诚',   '13900000031', '410101201011111234', 1, 3, 1, 5, '[2]',    '["咸香","微辣"]',       DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),
(32, 'openid_u32', '何欢',   '13900000032', '410101201112122345', 0, 3, 1, 6, '[2]',    '["清淡","高蛋白"]',     DATE_SUB(NOW(), INTERVAL 19 DAY), NOW()),
(33, 'openid_u33', '吕良',   '13900000033', '410101201213133456', 1, 3, 1, 9, '[2]',    '["微辣"]',             DATE_SUB(NOW(), INTERVAL 18 DAY), NOW()),
(34, 'openid_u34', '施琳',   '13900000034', '410101201314144567', 0, 3, 1, 10,'[2,4]',  '["清淡","低脂"]',       DATE_SUB(NOW(), INTERVAL 17 DAY), NOW()),
(35, 'openid_u35', '张弛',   '13900000035', '410101201415155678', 1, 3, 1, 3, '[2]',    '["咸香","高蛋白"]',     DATE_SUB(NOW(), INTERVAL 16 DAY), NOW()),
(36, 'openid_u36', '孔慧',   '13900000036', '410101201516166789', 0, 3, 1, 1, '[2]',    '["清淡"]',             DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
(37, 'openid_u37', '曹志',   '13900000037', '410101201617177890', 1, 3, 1, 2, '[2,3]',  '["咸香","微辣"]',       DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),
(38, 'openid_u38', '严丽',   '13900000038', '410101201718188901', 0, 3, 1, 5, '[3]',    '["咸香"]',             DATE_SUB(NOW(), INTERVAL 13 DAY), NOW()),
(39, 'openid_u39', '华峰',   '13900000039', '410101201819199012', 1, 3, 1, 7, '[2]',    '["高蛋白","清淡"]',     DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(40, 'openid_u40', '金玉',   '13900000040', '410101201920200123', 0, 3, 1, 8, '[2]',    '["甜口","清淡"]',       DATE_SUB(NOW(), INTERVAL 11 DAY), NOW());

-- 冷启动用户 (preference_completed=0, 编号41-50)
INSERT INTO user (id, openid, name, phone, id_number, gender, cabin_type, preference_completed, current_flight_id, create_time, update_time) VALUES
(41, 'openid_u41', '冷启1',  '13900000041', '510101200001011234', 1, 3, 0, 1,  DATE_SUB(NOW(), INTERVAL 3 DAY), NULL),
(42, 'openid_u42', '冷启2',  '13900000042', '510101200102022345', 0, 3, 0, 1,  DATE_SUB(NOW(), INTERVAL 3 DAY), NULL),
(43, 'openid_u43', '冷启3',  '13900000043', '510101200203033456', 1, 3, 0, 2,  DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),
(44, 'openid_u44', '冷启4',  '13900000044', '510101200304044567', 0, 2, 0, 3,  DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),
(45, 'openid_u45', '冷启5',  '13900000045', '510101200405055678', 1, 1, 0, 5,  DATE_SUB(NOW(), INTERVAL 1 DAY), NULL),
(46, 'openid_u46', '冷启6',  '13900000046', '510101200506066789', 0, 3, 0, NULL, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL),
(47, 'openid_u47', '冷启7',  '13900000047', '510101200607077890', 1, 3, 0, NULL, NOW(), NULL),
(48, 'openid_u48', '冷启8',  '13900000048', '510101200708088901', 0, 3, 0, NULL, NOW(), NULL),
(49, 'openid_u49', '冷启9',  '13900000049', '510101200809099012', 1, 3, 0, NULL, NOW(), NULL),
(50, 'openid_u50', '冷启10', '13900000050', '510101200910100123', 0, 3, 0, NULL, NOW(), NULL);

-- ===== 7. 推荐日志（构建丰富行为数据） =====
-- 为活跃航班上的用户生成推荐日志
-- 用户1-5(头等舱)在FUS6101上的推荐记录
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, user_rating, create_time) VALUES
(1, 1, '[1,2,3,6,7,8,29,11]', 'MANUAL_SELECTED:dishId=1:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(1, 1, '[2,4,7,9,30,6]', 'MANUAL_SELECTED:dishId=2:mealOrder=2', 4, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(2, 1, '[1,3,6,7,11,29]', 'MANUAL_SELECTED:dishId=11:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(2, 1, '[2,4,9,30,6,7]', 'MANUAL_SELECTED:dishId=9:mealOrder=2', 4, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(3, 1, '[1,2,6,7,29,11,9,30]', 'MANUAL_SELECTED:dishId=29:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(4, 5, '[1,2,3,6,7]', 'MANUAL_SELECTED:dishId=1:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(4, 5, '[2,3,6,7]', 'MANUAL_SELECTED:dishId=7:mealOrder=2', 4, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(5, 5, '[1,2,6,7,8]', 'MANUAL_SELECTED:dishId=8:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 3 DAY));

-- 用户11-20(口味漂移组)生成行为数据——初期偏好咸香，后期转向微辣
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, user_rating, create_time) VALUES
(11, 1, '[1,2,3,4,6,7]', 'MANUAL_SELECTED:dishId=1:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 25 DAY)),
(11, 5, '[1,2,3,6,7]',   'MANUAL_SELECTED:dishId=1:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 20 DAY)),
(11, 1, '[1,2,3,6,7,8,9,11]', 'CLICK:dishId=2:mealOrder=1|MANUAL_SELECTED:dishId=2:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(12, 1, '[1,2,4,6,7]', 'MANUAL_SELECTED:dishId=2:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 20 DAY)),
(12, 6, '[2,3,4,6]',   'MANUAL_SELECTED:dishId=2:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 15 DAY)),
(12, 2, '[2,4,6,12,13]', 'CLICK:dishId=4:mealOrder=1|MANUAL_SELECTED:dishId=4:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(13, 3, '[1,2,12,14,6,10,25,27]', 'MANUAL_SELECTED:dishId=12:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 18 DAY)),
(13, 3, '[2,6,7,25,27]', 'CLICK:dishId=27:mealOrder=1|MANUAL_SELECTED:dishId=27:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 3 DAY));

-- 用户6-10(商务舱)的行为数据
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, user_rating, create_time) VALUES
(6, 2, '[2,4,6,12,13,7,9]', 'MANUAL_SELECTED:dishId=2:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(6, 2, '[4,6,7,9,12]', 'MANUAL_SELECTED:dishId=7:mealOrder=2', 4, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(7, 2, '[2,4,6,12,13,7,9]', 'MANUAL_SELECTED:dishId=4:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 8 DAY)),
(8, 3, '[1,2,6,10,12,14,25,27,11,30]', 'MANUAL_SELECTED:dishId=6:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(9, 5, '[1,2,3,6,7]', 'MANUAL_SELECTED:dishId=6:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(10, 6, '[3,4,6]', 'MANUAL_SELECTED:dishId=3:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- 用户21-40(普通经济舱)的行为数据——批量生成，每个用户1-3条
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, user_rating, create_time) VALUES
(21, 1, '[1,2,3,6,7,8]', 'MANUAL_SELECTED:dishId=1:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 15 DAY)),
(21, 5, '[1,2,3,6,7]', 'MANUAL_SELECTED:dishId=2:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(22, 2, '[2,4,6,12,13]', 'MANUAL_SELECTED:dishId=6:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 12 DAY)),
(22, 6, '[3,4,6]', 'MANUAL_SELECTED:dishId=6:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(23, 3, '[1,2,12,14,6]', 'MANUAL_SELECTED:dishId=14:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(24, 5, '[1,2,3,6,7,8]', 'MANUAL_SELECTED:dishId=8:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 8 DAY)),
(25, 6, '[3,4,6]', 'MANUAL_SELECTED:dishId=4:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(26, 7, '[6,7,8,9]', 'MANUAL_SELECTED:dishId=7:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 12 DAY)),
(27, 8, '[1,2,12,13]', 'MANUAL_SELECTED:dishId=2:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 15 DAY)),
(28, 1, '[5,6,7,8,16,17,18]', 'MANUAL_SELECTED:dishId=17:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(29, 2, '[2,4,6,12,13]', 'MANUAL_SELECTED:dishId=4:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(30, 3, '[6,8,10,25,26]', 'MANUAL_SELECTED:dishId=10:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(31, 5, '[1,2,3,6,7]', 'MANUAL_SELECTED:dishId=3:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(32, 6, '[3,4,6]', 'CLICK:dishId=3:mealOrder=1|MANUAL_SELECTED:dishId=3:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(33, 1, '[1,2,3,6,7,8,11]', 'MANUAL_SELECTED:dishId=3:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(34, 10,'[6,7,12,13,14,15]', 'MANUAL_SELECTED:dishId=14:mealOrder=1', 5, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(35, 3, '[1,2,12,14,6]', 'MANUAL_SELECTED:dishId=1:mealOrder=1', 4, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- 追加CLICK行为（用户浏览了但未选择）
INSERT INTO recommendation_log (user_id, flight_id, recommended_dishes, user_feedback, create_time) VALUES
(21, 7, '[6,7,8,9]', 'CLICK:dishId=6:mealOrder=1', DATE_SUB(NOW(), INTERVAL 30 DAY)),
(22, 8, '[1,2,12,13]', 'CLICK:dishId=1:mealOrder=1', DATE_SUB(NOW(), INTERVAL 28 DAY)),
(23, 1, '[1,2,3,6,7,8]', 'CLICK:dishId=3:mealOrder=1', DATE_SUB(NOW(), INTERVAL 25 DAY)),
(24, 2, '[2,4,6,12,13]', 'CLICK:dishId=6:mealOrder=1', DATE_SUB(NOW(), INTERVAL 22 DAY)),
(25, 3, '[1,2,12,14,6]', 'CLICK:dishId=2:mealOrder=1', DATE_SUB(NOW(), INTERVAL 20 DAY)),
(26, 5, '[1,2,3,6,7]', 'CLICK:dishId=7:mealOrder=1', DATE_SUB(NOW(), INTERVAL 18 DAY)),
(11, 8, '[1,2,12,13]', 'CLICK:dishId=2:mealOrder=1', DATE_SUB(NOW(), INTERVAL 35 DAY)),
(12, 7, '[6,7,8,9]', 'CLICK:dishId=6:mealOrder=1', DATE_SUB(NOW(), INTERVAL 32 DAY));

-- ===== 8. 餐食预选 =====
INSERT INTO meal_selection (number, status, user_id, flight_id, meal_order, create_time, update_time) VALUES
-- 活跃航班上的预选
('MANUAL-001', 3, 1,  1, 1, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY)),
('MANUAL-002', 3, 1,  1, 2, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY)),
('MANUAL-003', 3, 2,  1, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
('MANUAL-004', 3, 3,  1, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
('MANUAL-005', 3, 11, 1, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
('MANUAL-006', 3, 12, 2, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
('MANUAL-007', 3, 13, 3, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
('MANUAL-008', 3, 21, 1, 1, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY)),
('MANUAL-009', 3, 22, 2, 1, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY)),
('MANUAL-010', 3, 33, 1, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
-- 已到达航班上的预选（用于产生评分任务）
('MANUAL-011', 3, 4,  5, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
('MANUAL-012', 3, 4,  5, 2, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
('MANUAL-013', 3, 5,  5, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
('MANUAL-014', 3, 9,  5, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
('MANUAL-015', 3, 10, 6, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
('MANUAL-016', 3, 24, 5, 1, DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY)),
('MANUAL-017', 3, 25, 6, 1, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY)),
('MANUAL-018', 3, 31, 5, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
('MANUAL-019', 3, 32, 6, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
('MANUAL-020', 3, 6,  2, 1, DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY)),
-- 历史航班上的预选（验证长期行为信号）
('MANUAL-021', 3, 26, 7, 1, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY)),
('MANUAL-022', 3, 27, 8, 1, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY)),
('MANUAL-023', 3, 39, 7, 1, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY)),
('MANUAL-024', 3, 40, 8, 1, DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY));

-- ===== 9. 评分任务（覆盖四种状态） =====
INSERT INTO flight_service_rating (user_id, flight_id, rating_score, rating_status, first_visible_at, next_remind_at, defer_count, submitted_at, expire_at, create_time, update_time) VALUES
-- SUBMITTED
(4,  5, 5, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), 0, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
(5,  5, 5, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 0, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
(9,  5, 5, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), 0, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
(10, 6, 4, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), 0, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
(24, 5, 5, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY), 0, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY)),
(25, 6, 4, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), 0, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
(26, 7, 5, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), 0, DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY)),
(31, 5, 4, 'SUBMITTED', DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), 0, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
-- PENDING
(32, 6, NULL, 'PENDING', DATE_SUB(NOW(), INTERVAL 3 DAY), NOW(), 0, NULL, DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(39, 7, NULL, 'PENDING', DATE_SUB(NOW(), INTERVAL 11 DAY), NOW(), 0, NULL, DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(40, 8, NULL, 'PENDING', DATE_SUB(NOW(), INTERVAL 10 DAY), NOW(), 0, NULL, DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), NOW()),
(21, 5, NULL, 'PENDING', NOW(), NOW(), 0, NULL, DATE_ADD(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(22, 6, NULL, 'PENDING', NOW(), NOW(), 0, NULL, DATE_ADD(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
-- DEFERRED
(27, 8, NULL, 'DEFERRED', DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), 1, NULL, DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY)),
-- EXPIRED（用户35在历史航班8上过期未评分）
(35, 8, NULL, 'EXPIRED', DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 23 DAY), 2, NULL, DATE_SUB(NOW(), INTERVAL 29 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 29 DAY));

-- ===== 10. 航班公告 =====
INSERT INTO flight_announcement (flight_id, title, content, status, create_user, create_time, update_time) VALUES
(1, 'FUS6101 选餐已开放', '尊敬的旅客，您乘坐的FUS6101航班餐食预选已开放，请在5月15日20:00前完成选餐。', 1, 1, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(1, 'FUS6101 选餐截止提醒T-12', '距离选餐截止还有12小时，请尽快完成选餐。', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
(2, 'FUS6202 选餐已开放', '尊敬的旅客，您乘坐的FUS6202航班餐食预选已开放，请在5月16日06:00前完成选餐。', 1, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW());

SET FOREIGN_KEY_CHECKS = 1;

-- ===== 验证 =====
SELECT 'employee' AS tbl, COUNT(*) AS cnt FROM employee
UNION ALL SELECT 'category', COUNT(*) FROM category
UNION ALL SELECT 'dish', COUNT(*) FROM dish
UNION ALL SELECT 'flight_info', COUNT(*) FROM flight_info
UNION ALL SELECT 'flight_dish', COUNT(*) FROM flight_dish
UNION ALL SELECT 'user', COUNT(*) FROM user
UNION ALL SELECT 'recommendation_log', COUNT(*) FROM recommendation_log
UNION ALL SELECT 'meal_selection', COUNT(*) FROM meal_selection
UNION ALL SELECT 'flight_service_rating', COUNT(*) FROM flight_service_rating
UNION ALL SELECT 'flight_announcement', COUNT(*) FROM flight_announcement
ORDER BY tbl;
