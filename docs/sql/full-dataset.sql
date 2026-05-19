-- ============================================================
-- 航空餐食推荐系统 — 完整数据集
-- 菜品50+ | 管理员5+ | 用户100+ | 日志500+ | 舱位差异化
-- 演示用户: 胡屿科 510411200309180910 头等舱
-- ============================================================
USE aviation_food_recommend;

-- 清空所有数据（按外键依赖逆序）
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE meal_selection;
TRUNCATE TABLE recommendation_log;
TRUNCATE TABLE flight_service_rating;
TRUNCATE TABLE flight_announcement;
TRUNCATE TABLE flight_dish;
TRUNCATE TABLE flight_info;
TRUNCATE TABLE dish;
TRUNCATE TABLE category;
TRUNCATE TABLE user;
TRUNCATE TABLE employee;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. 管理员 (6人)
-- ============================================================
INSERT INTO employee (account, username, name, password, phone, status, gender, create_time) VALUES
('admin','admin','胡屿科','e10adc3949ba59abbe56e057f20f883e','13800000000',1,1,NOW()),
('ops01','ops01','张运营','e10adc3949ba59abbe56e057f20f883e','13800000001',1,0,NOW()),
('ops02','ops02','李乘务','e10adc3949ba59abbe56e057f20f883e','13800000002',1,1,NOW()),
('chef01','chef01','王主厨','e10adc3949ba59abbe56e057f20f883e','13800000003',1,1,NOW()),
('super','super','赵超管','e10adc3949ba59abbe56e057f20f883e','13800000004',1,1,NOW()),
('test01','test01','测试员','e10adc3949ba59abbe56e057f20f883e','13800000005',1,0,NOW());

UPDATE employee SET create_user = 1, update_user = 1 WHERE create_user IS NULL;

-- ============================================================
-- 2. 菜品分类 (8类)
-- ============================================================
INSERT INTO category (type, name, sort, status, create_user) VALUES
(1,'中式热菜',1,1,1),
(1,'西式主菜',2,1,1),
(1,'日韩料理',3,1,1),
(1,'面点主食',4,1,1),
(1,'清真专供',5,1,1),
(1,'素食轻食',6,1,1),
(1,'儿童套餐',7,1,1),
(1,'汤品饮品',8,1,1);
SET @cat_chinese = 1; SET @cat_western = 2; SET @cat_japanese = 3;
SET @cat_noodle = 4; SET @cat_halal = 5; SET @cat_vegan = 6;
SET @cat_kids = 7; SET @cat_soup = 8;

-- ============================================================
-- 3. 菜品 (56道) — 头等18 + 商务18 + 经济20
--    meal_type: 1=儿童 2=标准 3=清真 4=素食
--    cabin_tier: 1=头等高端 2=商务精致 3=经济大众
-- ============================================================

-- ---------- 头等舱高端菜品 (18道) ----------
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('澳洲M9和牛菲力牛排',@cat_western,2,'["咸香","高蛋白"]',1,40,'澳洲M9级和牛菲力配黑松露红酒汁与焗土豆'),
('法式香煎鹅肝配无花果',@cat_western,2,'["咸香","高蛋白"]',1,35,'法国进口鹅肝配焦糖无花果与黄油面包片'),
('波士顿龙虾烩意面',@cat_western,2,'["咸香","微辣"]',1,40,'整只波士顿龙虾配手工意大利宽面与龙虾汁'),
('黑松露野菌奶油浓汤',@cat_soup,4,'["清淡","低脂"]',1,60,'意大利黑松露配牛肝菌羊肚菌与鲜奶油'),
('慢烤新西兰法式羊排',@cat_western,2,'["咸香","高蛋白"]',1,35,'新西兰草饲羊排配迷迭香薄荷酱与烤时蔬'),
('俄罗斯鲟鱼子酱配薄饼',@cat_western,2,'["咸香","甜口"]',1,25,'俄罗斯进口鲟鱼子酱配传统俄式布林饼'),
('挪威烟熏三文鱼塔塔',@cat_western,2,'["咸香","高蛋白"]',1,45,'挪威空运烟熏三文鱼配牛油果塔塔酱'),
('日式综合刺身盛合',@cat_japanese,2,'["清淡","高蛋白","低脂"]',1,40,'蓝鳍金枪鱼三文鱼甜虾北极贝刺身拼盘'),
('清蒸东星斑配姜葱',@cat_chinese,2,'["清淡","高蛋白","低脂"]',1,30,'鲜活东星斑清蒸配姜葱丝与蒸鱼豉油'),
('黑椒安格斯牛柳粒',@cat_chinese,2,'["咸香","微辣","高蛋白"]',1,50,'安格斯牛柳粒配彩椒洋葱黑椒汁'),
('金汤小米扣辽参',@cat_chinese,2,'["清淡","高蛋白"]',1,40,'大连辽参配小米金汤与时蔬'),
('鲍汁扣花菇鹅掌',@cat_chinese,2,'["咸香","高蛋白"]',1,35,'南非干鲍汁扣花菇与鲜鹅掌'),
('松茸花胶炖土鸡',@cat_soup,2,'["清淡","高蛋白","低脂"]',1,50,'云南松茸配花胶与土鸡清炖四小时'),
('香煎银鳕鱼配柠檬黄油',@cat_western,2,'["清淡","低脂","高蛋白"]',1,45,'阿拉斯加银鳕鱼香煎配柠檬黄油汁'),
('蒲烧鳗鱼饭',@cat_japanese,2,'["甜口","咸香"]',1,55,'活鳗蒲烧配秘制酱汁与越光米饭'),
('红酒烩牛尾配土豆泥',@cat_western,2,'["咸香","高蛋白"]',1,40,'澳洲牛尾红酒慢炖六小时配奶油土豆泥'),
('葱烧海参配时蔬',@cat_chinese,2,'["咸香","高蛋白"]',1,45,'大连刺参葱烧配当季时令蔬菜'),
('天妇罗炸虾拼盘',@cat_japanese,2,'["清淡","咸香"]',1,55,'大虾蔬菜天妇罗配抹茶盐与天汁');

-- ---------- 商务舱精致菜品 (18道) ----------
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('宫保虾球配蛋炒饭',@cat_chinese,2,'["微辣","咸香"]',1,80,'精选大虾球配宫保酱汁与茉莉香米蛋炒饭'),
('红烧鲍鱼捞面',@cat_noodle,2,'["咸香","高蛋白"]',1,70,'鲜鲍鱼配红烧酱汁与手工拉面'),
('黑椒牛柳炒乌冬',@cat_noodle,2,'["咸香","微辣"]',1,85,'澳洲牛柳配日式乌冬与黑椒汁'),
('泰式咖喱鸡肉配香米',@cat_chinese,2,'["微辣","咸香"]',1,90,'泰式黄咖喱鸡腿配巴斯马蒂香米'),
('清蒸银鳕鱼配时蔬',@cat_chinese,2,'["清淡","低脂","高蛋白"]',1,75,'阿拉斯加银鳕鱼清蒸配当季时蔬'),
('蜜汁叉烧双拼饭',@cat_chinese,2,'["咸香","甜口"]',1,95,'蜜汁叉烧拼玫瑰豉油鸡配丝苗米饭'),
('XO酱海鲜炒饭',@cat_noodle,2,'["微辣","咸香"]',1,100,'瑶柱虾仁鱿鱼配XO酱炒茉莉香米'),
('照烧鸡腿排配蔬菜',@cat_japanese,2,'["甜口","咸香"]',1,80,'去骨鸡腿照烧配时蔬与芝麻'),
('红烧牛腩面',@cat_noodle,2,'["咸香","微辣"]',1,90,'牛腱子红烧配手工拉面与青菜'),
('梅菜扣肉配荷叶饼',@cat_chinese,2,'["咸香","甜口"]',1,80,'五花肉梅菜扣蒸配荷叶夹饼'),
('椒盐大虾配炒饭',@cat_chinese,2,'["咸香","微辣"]',1,85,'椒盐炸虾配蛋炒饭与时蔬'),
('日式亲子丼',@cat_japanese,2,'["清淡","甜口"]',1,90,'鸡腿肉鸡蛋洋葱配日式酱汁盖饭'),
('蒜香黄油焗青口',@cat_western,2,'["咸香","高蛋白"]',1,70,'新西兰青口贝蒜香黄油焗配法棍'),
('糖醋里脊配白米饭',@cat_chinese,2,'["甜口","咸香"]',1,95,'猪里脊糖醋汁配白米饭'),
('韩国泡菜炒饭',@cat_japanese,2,'["微辣","咸香"]',1,100,'韩式泡菜五花肉炒饭配煎蛋'),
('意大利肉酱千层面',@cat_western,2,'["咸香","甜口"]',1,75,'手工千层面配博洛尼亚肉酱与芝士'),
('海南鸡饭套餐',@cat_chinese,2,'["清淡","咸香"]',1,85,'文昌鸡配鸡油饭与三种蘸酱'),
('日式豚骨拉面',@cat_noodle,2,'["咸香","高蛋白"]',1,80,'猪骨浓汤拉面配叉烧溏心蛋');

-- ---------- 经济舱大众美食 (20道) ----------
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('红烧牛肉面',@cat_noodle,2,'["咸香","微辣"]',1,150,'牛腱子红烧配手工拉面青菜'),
('宫保鸡丁盖饭',@cat_chinese,2,'["微辣","咸香"]',1,150,'经典宫保鸡丁配白米饭'),
('番茄鸡蛋打卤面',@cat_noodle,2,'["清淡","甜口"]',1,150,'新鲜番茄炒蛋配手工面条'),
('鱼香肉丝饭',@cat_chinese,2,'["微辣","甜口"]',1,140,'经典鱼香肉丝配白米饭'),
('回锅肉盖饭',@cat_chinese,2,'["微辣","咸香"]',1,140,'川味回锅肉配白米饭与时蔬'),
('香菇滑鸡饭',@cat_chinese,2,'["清淡","咸香"]',1,140,'香菇蒸滑鸡配白米饭'),
('麻婆豆腐饭',@cat_chinese,4,'["微辣","咸香"]',1,120,'川味麻婆豆腐配白米饭素食'),
('清炒时蔬配小米粥',@cat_vegan,4,'["清淡","低脂"]',1,130,'当季时蔬清炒配小米粥素食'),
('鸡蛋火腿三明治',@cat_western,2,'["清淡","低脂"]',1,150,'火腿鸡蛋三明治配鲜切水果酸奶'),
('扬州什锦炒饭',@cat_noodle,2,'["咸香"]',1,150,'火腿青豆虾仁鸡蛋什锦炒饭'),
('黄焖鸡米饭',@cat_chinese,2,'["咸香","微辣"]',1,140,'黄焖鸡腿肉配米饭与时蔬'),
('酸辣粉',@cat_noodle,2,'["微辣","咸香"]',1,130,'红薯粉配酸辣汤料花生碎香菜'),
('榨菜肉丝面',@cat_noodle,2,'["清淡","咸香"]',1,140,'榨菜肉丝配手工面条与高汤'),
('咖喱土豆盖饭',@cat_vegan,4,'["微辣","咸香"]',1,120,'日式咖喱土豆胡萝卜配白米饭素食'),
('蛋炒饭配小菜',@cat_noodle,2,'["清淡","咸香"]',1,150,'蛋炒饭配酱菜与时蔬小炒'),
('素菜包子配豆浆',@cat_vegan,4,'["清淡","低脂"]',1,140,'蔬菜香菇包子配现磨豆浆素食'),
('红烧鸡腿饭',@cat_chinese,2,'["咸香","甜口"]',1,140,'红烧鸡腿配白米饭与卤蛋'),
('麻辣香锅便当',@cat_chinese,2,'["微辣","咸香"]',1,120,'麻辣香锅风味便当配米饭'),
('清汤牛肉面',@cat_noodle,2,'["清淡","咸香"]',1,140,'清炖牛腱子汤面配时蔬'),
('鸡肉蔬菜沙拉',@cat_vegan,2,'["清淡","低脂","高蛋白"]',1,130,'鸡胸肉配鲜蔬沙拉与油醋汁');

-- ---------- 清真专供菜品 (4道) ----------
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('清真红烧牛肉饭',@cat_halal,3,'["咸香","微辣"]',1,80,'清真认证红烧牛肉配白米饭'),
('清真烤羊排配米饭',@cat_halal,3,'["咸香","高蛋白"]',1,70,'清真认证烤羊排配米饭与时蔬'),
('清真大盘鸡拌面',@cat_halal,3,'["微辣","咸香"]',1,90,'清真大盘鸡配手工宽面'),
('清真蔬菜咖喱饭',@cat_halal,3,'["微辣","清淡"]',1,85,'清真蔬菜咖喱配巴斯马蒂米饭');

-- ---------- 儿童专属菜品 (4道) ----------
INSERT INTO dish (name, category_id, meal_type, flavor_tags, status, stock, detail) VALUES
('小飞机儿童套餐A',@cat_kids,1,'["清淡","甜口"]',1,60,'鸡块意面玉米粒配水果与卡通饼干'),
('小飞机儿童套餐B',@cat_kids,1,'["清淡","咸香"]',1,60,'鱼肉饭团蒸蛋西兰花配果汁'),
('卡通三明治套餐',@cat_kids,1,'["清淡","甜口"]',1,55,'卡通造型三明治配牛奶与水果杯'),
('迷你汉堡套餐',@cat_kids,1,'["咸香","甜口"]',1,55,'迷你牛肉汉堡配薯角与苹果汁');

-- 菜品 ID: 1-18头等 | 19-36商务 | 37-56经济 | 57-60清真 | 61-64儿童
SET @fc_start = 1;

-- ============================================================
-- 4. 航班 (8个，6个运营中 + 2个已结束)
-- ============================================================
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8001','北京','上海','2026-05-22 08:00:00','2026-05-22 10:30:00',150,1,'2026-05-21 20:00:00',1,1,NOW());
SET @f1 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8002','上海','成都','2026-05-23 07:00:00','2026-05-23 10:00:00',180,2,'2026-05-22 18:00:00',1,1,NOW());
SET @f2 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8003','广州','北京','2026-05-25 09:00:00','2026-05-25 12:30:00',210,2,'2026-05-24 20:00:00',1,1,NOW());
SET @f3 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8004','深圳','乌鲁木齐','2026-05-28 06:30:00','2026-05-28 11:30:00',300,2,'2026-05-27 18:00:00',1,1,NOW());
SET @f4 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8005','成都','杭州','2026-06-01 10:00:00','2026-06-01 12:30:00',150,1,'2026-05-31 22:00:00',1,1,NOW());
SET @f5 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8006','北京','三亚','2026-06-05 07:30:00','2026-06-05 11:30:00',240,2,'2026-06-04 18:00:00',1,1,NOW());
SET @f6 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8007','上海','昆明','2026-06-10 08:00:00','2026-06-10 11:30:00',210,2,'2026-06-09 20:00:00',1,1,NOW());
SET @f7 = LAST_INSERT_ID();
INSERT INTO flight_info (flight_number, departure, destination, departure_time, arrival_time, duration_minutes, meal_count, selection_deadline, status, create_user, create_time) VALUES
('FUS8008','西安','厦门','2026-06-15 13:00:00','2026-06-15 15:30:00',150,1,'2026-06-15 01:00:00',1,1,NOW());
SET @f8 = LAST_INSERT_ID();

-- ============================================================
-- 5. 航线-菜品绑定 (按舱位三级绑定)
--    头等舱绑定 @fc_start .. @fc_start+17
--    商务舱绑定 @fc_start+18 .. @fc_start+35
--    经济舱绑定 @fc_start+36 .. @fc_start+55
--    清真 + 儿童 + 素食适当混入各舱位
-- ============================================================

-- FUS8001(北京-上海) 1餐 精品航线 — 头等8+商务8+经济8 = 24
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f1,@fc_start,1,1),(@f1,@fc_start+1,1,2),(@f1,@fc_start+2,1,3),(@f1,@fc_start+3,1,4),
(@f1,@fc_start+4,1,5),(@f1,@fc_start+5,1,6),(@f1,@fc_start+6,1,7),(@f1,@fc_start+7,1,8);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f1,@fc_start+18,2,1),(@f1,@fc_start+19,2,2),(@f1,@fc_start+20,2,3),(@f1,@fc_start+21,2,4),
(@f1,@fc_start+22,2,5),(@f1,@fc_start+23,2,6),(@f1,@fc_start+24,2,7),(@f1,@fc_start+25,2,8);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f1,@fc_start+36,3,1),(@f1,@fc_start+37,3,2),(@f1,@fc_start+38,3,3),(@f1,@fc_start+39,3,4),
(@f1,@fc_start+40,3,5),(@f1,@fc_start+41,3,6),(@f1,@fc_start+42,3,7),(@f1,@fc_start+43,3,8);

-- FUS8002(上海-成都) 2餐 长途 — 头等10+商务10+经济10
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f2,@fc_start,1,1),(@f2,@fc_start+2,1,2),(@f2,@fc_start+4,1,3),(@f2,@fc_start+6,1,4),
(@f2,@fc_start+8,1,5),(@f2,@fc_start+10,1,6),(@f2,@fc_start+12,1,7),(@f2,@fc_start+14,1,8),
(@f2,@fc_start+16,1,9),(@f2,@fc_start+17,1,10);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f2,@fc_start+18,2,1),(@f2,@fc_start+20,2,2),(@f2,@fc_start+22,2,3),(@f2,@fc_start+24,2,4),
(@f2,@fc_start+26,2,5),(@f2,@fc_start+28,2,6),(@f2,@fc_start+30,2,7),(@f2,@fc_start+32,2,8),
(@f2,@fc_start+34,2,9),(@f2,@fc_start+35,2,10);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f2,@fc_start+36,3,1),(@f2,@fc_start+38,3,2),(@f2,@fc_start+40,3,3),(@f2,@fc_start+42,3,4),
(@f2,@fc_start+44,3,5),(@f2,@fc_start+46,3,6),(@f2,@fc_start+48,3,7),(@f2,@fc_start+50,3,8),
(@f2,@fc_start+52,3,9),(@f2,@fc_start+54,3,10);

-- FUS8003(广州-北京) 2餐
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f3,@fc_start+1,1,1),(@f3,@fc_start+3,1,2),(@f3,@fc_start+5,1,3),(@f3,@fc_start+7,1,4),
(@f3,@fc_start+9,1,5),(@f3,@fc_start+11,1,6),(@f3,@fc_start+13,1,7),(@f3,@fc_start+15,1,8);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f3,@fc_start+19,2,1),(@f3,@fc_start+21,2,2),(@f3,@fc_start+23,2,3),(@f3,@fc_start+25,2,4),
(@f3,@fc_start+27,2,5),(@f3,@fc_start+29,2,6),(@f3,@fc_start+31,2,7),(@f3,@fc_start+33,2,8);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f3,@fc_start+37,3,1),(@f3,@fc_start+39,3,2),(@f3,@fc_start+41,3,3),(@f3,@fc_start+43,3,4),
(@f3,@fc_start+45,3,5),(@f3,@fc_start+47,3,6),(@f3,@fc_start+49,3,7),(@f3,@fc_start+51,3,8);

-- FUS8004(深圳-乌鲁木齐) 2餐 超长途 — 头等10+商务10+经济12
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f4,@fc_start,1,1),(@f4,@fc_start+2,1,2),(@f4,@fc_start+4,1,3),(@f4,@fc_start+6,1,4),
(@f4,@fc_start+8,1,5),(@f4,@fc_start+10,1,6),(@f4,@fc_start+12,1,7),(@f4,@fc_start+14,1,8),
(@f4,@fc_start+15,1,9),(@f4,@fc_start+17,1,10);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f4,@fc_start+20,2,1),(@f4,@fc_start+22,2,2),(@f4,@fc_start+24,2,3),(@f4,@fc_start+26,2,4),
(@f4,@fc_start+28,2,5),(@f4,@fc_start+30,2,6),(@f4,@fc_start+32,2,7),(@f4,@fc_start+34,2,8),
(@f4,@fc_start+54,2,9),(@f4,@fc_start+55,2,10);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f4,@fc_start+36,3,1),(@f4,@fc_start+38,3,2),(@f4,@fc_start+40,3,3),(@f4,@fc_start+42,3,4),
(@f4,@fc_start+44,3,5),(@f4,@fc_start+46,3,6),(@f4,@fc_start+48,3,7),(@f4,@fc_start+50,3,8),
(@f4,@fc_start+51,3,9),(@f4,@fc_start+52,3,10),(@f4,@fc_start+53,3,11),(@f4,@fc_start+55,3,12);

-- FUS8005(成都-杭州) 1餐
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f5,@fc_start+1,1,1),(@f5,@fc_start+3,1,2),(@f5,@fc_start+5,1,3),(@f5,@fc_start+7,1,4),(@f5,@fc_start+9,1,5),(@f5,@fc_start+11,1,6);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f5,@fc_start+18,2,1),(@f5,@fc_start+20,2,2),(@f5,@fc_start+22,2,3),(@f5,@fc_start+24,2,4),(@f5,@fc_start+26,2,5),(@f5,@fc_start+28,2,6);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f5,@fc_start+36,3,1),(@f5,@fc_start+38,3,2),(@f5,@fc_start+40,3,3),(@f5,@fc_start+42,3,4),
(@f5,@fc_start+44,3,5),(@f5,@fc_start+46,3,6),(@f5,@fc_start+48,3,7),(@f5,@fc_start+50,3,8);

-- FUS8006(北京-三亚) 2餐 旅游航线
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f6,@fc_start+2,1,1),(@f6,@fc_start+4,1,2),(@f6,@fc_start+6,1,3),(@f6,@fc_start+8,1,4),
(@f6,@fc_start+10,1,5),(@f6,@fc_start+14,1,6);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f6,@fc_start+19,2,1),(@f6,@fc_start+21,2,2),(@f6,@fc_start+23,2,3),(@f6,@fc_start+25,2,4),
(@f6,@fc_start+27,2,5),(@f6,@fc_start+29,2,6),(@f6,@fc_start+31,2,7),(@f6,@fc_start+53,2,8);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f6,@fc_start+37,3,1),(@f6,@fc_start+39,3,2),(@f6,@fc_start+41,3,3),(@f6,@fc_start+43,3,4),
(@f6,@fc_start+45,3,5),(@f6,@fc_start+47,3,6),(@f6,@fc_start+49,3,7),(@f6,@fc_start+51,3,8);

-- FUS8007(上海-昆明) 2餐
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f7,@fc_start,1,1),(@f7,@fc_start+3,1,2),(@f7,@fc_start+5,1,3),(@f7,@fc_start+7,1,4),(@f7,@fc_start+9,1,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f7,@fc_start+18,2,1),(@f7,@fc_start+22,2,2),(@f7,@fc_start+24,2,3),(@f7,@fc_start+26,2,4),(@f7,@fc_start+28,2,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f7,@fc_start+38,3,1),(@f7,@fc_start+40,3,2),(@f7,@fc_start+42,3,3),(@f7,@fc_start+44,3,4),
(@f7,@fc_start+46,3,5),(@f7,@fc_start+48,3,6),(@f7,@fc_start+50,3,7);

-- FUS8008(西安-厦门) 1餐
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f8,@fc_start+1,1,1),(@f8,@fc_start+4,1,2),(@f8,@fc_start+6,1,3),(@f8,@fc_start+11,1,4),(@f8,@fc_start+13,1,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f8,@fc_start+20,2,1),(@f8,@fc_start+23,2,2),(@f8,@fc_start+25,2,3),(@f8,@fc_start+27,2,4),(@f8,@fc_start+30,2,5);
INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort) VALUES
(@f8,@fc_start+36,3,1),(@f8,@fc_start+39,3,2),(@f8,@fc_start+41,3,3),(@f8,@fc_start+43,3,4),
(@f8,@fc_start+45,3,5),(@f8,@fc_start+47,3,6),(@f8,@fc_start+49,3,7);

