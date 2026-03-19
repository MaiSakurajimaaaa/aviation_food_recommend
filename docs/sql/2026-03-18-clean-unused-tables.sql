-- 清理未使用遗留表（手动执行）
-- 适用：MySQL 8+
-- 建议先在测试环境验证，再在生产执行。

USE aviation_food_recommend;

-- 0) 执行前检查：确认是否仍有业务数据
SELECT 'flight_passenger' AS table_name, COUNT(*) AS row_count FROM flight_passenger
UNION ALL
SELECT 'meal_selection_detail' AS table_name, COUNT(*) AS row_count FROM meal_selection_detail
UNION ALL
SELECT 'setmeal' AS table_name, COUNT(*) AS row_count FROM setmeal
UNION ALL
SELECT 'setmeal_dish' AS table_name, COUNT(*) AS row_count FROM setmeal_dish;

-- 1) 可选：如需保底回滚能力，可先重命名备份（取消注释后执行）
-- RENAME TABLE flight_passenger TO flight_passenger_bak_20260318,
--              meal_selection_detail TO meal_selection_detail_bak_20260318,
--              setmeal TO setmeal_bak_20260318,
--              setmeal_dish TO setmeal_dish_bak_20260318;

-- 2) 正式删除遗留表
DROP TABLE IF EXISTS setmeal_dish;
DROP TABLE IF EXISTS setmeal;
DROP TABLE IF EXISTS meal_selection_detail;
DROP TABLE IF EXISTS flight_passenger;

-- 3) 说明：dish_flavor 当前仍有后端写入逻辑，不在本次清理范围内。
