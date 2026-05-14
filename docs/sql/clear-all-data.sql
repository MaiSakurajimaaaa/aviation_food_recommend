-- ====================================================
-- 清除 aviation_food_recommend 所有数据（保留表结构）
-- 执行前请确认：此操作不可逆
-- ====================================================

USE aviation_food_recommend;
SET FOREIGN_KEY_CHECKS = 0;

-- 按依赖链从叶子节点向根节点删除
TRUNCATE TABLE recommendation_log;
TRUNCATE TABLE flight_service_rating;
TRUNCATE TABLE meal_selection;
TRUNCATE TABLE flight_announcement;
TRUNCATE TABLE flight_dish;
TRUNCATE TABLE user;
TRUNCATE TABLE dish;
TRUNCATE TABLE category;
TRUNCATE TABLE flight_info;
TRUNCATE TABLE employee;

SET FOREIGN_KEY_CHECKS = 1;

-- 验证
SELECT table_name AS '表名', table_rows AS '行数'
FROM information_schema.tables
WHERE table_schema = 'aviation_food_recommend'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
