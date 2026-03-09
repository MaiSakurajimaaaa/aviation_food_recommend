-- 航空餐食免费化：删除 dish.price 字段（幂等）
USE aviation_food_recommend;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'dish'
      AND column_name = 'price'
  ),
  'ALTER TABLE dish DROP COLUMN price',
  'SELECT "skip drop dish.price"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 校验
SELECT column_name
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'dish'
ORDER BY ordinal_position;
