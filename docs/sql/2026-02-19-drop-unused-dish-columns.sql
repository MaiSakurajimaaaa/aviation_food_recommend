-- dish 表整洁化：删除未使用字段（幂等）
-- 目标删除列：region, calories, allergens, image, description
-- 安全处理：若 image/description 有值，先迁移到 pic/detail（仅在目标为空时迁移）

USE aviation_food_recommend;

-- 0) image -> pic（仅当两列都存在时执行）
SET @has_image = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'image'
);
SET @has_pic = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'pic'
);
SET @sql = IF(
  @has_image > 0 AND @has_pic > 0,
  'UPDATE dish SET pic = image WHERE (pic IS NULL OR pic = "") AND image IS NOT NULL AND image <> ""',
  'SELECT "skip image->pic migrate"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 1) description -> detail（仅当两列都存在时执行）
SET @has_description = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'description'
);
SET @has_detail = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'detail'
);
SET @sql = IF(
  @has_description > 0 AND @has_detail > 0,
  'UPDATE dish SET detail = description WHERE (detail IS NULL OR detail = "") AND description IS NOT NULL AND description <> ""',
  'SELECT "skip description->detail migrate"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) 删除未使用字段（存在才删）
SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'region'),
  'ALTER TABLE dish DROP COLUMN region',
  'SELECT "skip drop dish.region"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'calories'),
  'ALTER TABLE dish DROP COLUMN calories',
  'SELECT "skip drop dish.calories"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'allergens'),
  'ALTER TABLE dish DROP COLUMN allergens',
  'SELECT "skip drop dish.allergens"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'image'),
  'ALTER TABLE dish DROP COLUMN image',
  'SELECT "skip drop dish.image"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'description'),
  'ALTER TABLE dish DROP COLUMN description',
  'SELECT "skip drop dish.description"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3) 校验结果
SELECT column_name
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'dish'
ORDER BY ordinal_position;
