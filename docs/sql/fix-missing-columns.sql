-- ============================================================
-- 修复 recommendation_log 表缺失的列
-- 以 sql.sql DDL 为基准，补齐推荐日志表缺少的字段
-- ============================================================

USE aviation_food_recommend;

-- 补加 algorithm_type 列（若缺失，忽略已存在的错误）
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'aviation_food_recommend'
       AND table_name = 'recommendation_log'
       AND column_name = 'algorithm_type') = 0,
    'ALTER TABLE recommendation_log ADD COLUMN algorithm_type varchar(50) null AFTER recommended_dishes',
    'SELECT ''algorithm_type 已存在，跳过'' AS msg'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 补加 user_rating 列
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'aviation_food_recommend'
       AND table_name = 'recommendation_log'
       AND column_name = 'user_rating') = 0,
    'ALTER TABLE recommendation_log ADD COLUMN user_rating tinyint null AFTER algorithm_type',
    'SELECT ''user_rating 已存在，跳过'' AS msg'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 补加 user_feedback 列
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'aviation_food_recommend'
       AND table_name = 'recommendation_log'
       AND column_name = 'user_feedback') = 0,
    'ALTER TABLE recommendation_log ADD COLUMN user_feedback varchar(255) null AFTER user_rating',
    'SELECT ''user_feedback 已存在，跳过'' AS msg'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'aviation_food_recommend'
  AND table_name = 'recommendation_log'
ORDER BY ordinal_position;
