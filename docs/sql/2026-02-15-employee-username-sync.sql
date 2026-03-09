-- 目的：兼容旧库可视化字段 username，与系统真实登录字段 account 保持一致
-- 特点：幂等，可重复执行

USE aviation_food_recommend;

-- 1) 若不存在 username 列，则自动补齐
SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'employee'
      AND column_name = 'username'
  ),
  'SELECT "skip add username"',
  'ALTER TABLE employee ADD COLUMN username VARCHAR(64) NULL AFTER account'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) 同步 username <- account（只填充空值，避免覆盖你手工维护的数据）
UPDATE employee
SET username = account
WHERE (username IS NULL OR username = '')
  AND account IS NOT NULL
  AND account <> '';

-- 3) sex <- gender 映射（仅在两列都存在时执行；只填充空值）
SET @has_gender = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'employee'
    AND column_name = 'gender'
);

SET @has_sex = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'employee'
    AND column_name = 'sex'
);

SET @sql = IF(
  @has_gender > 0 AND @has_sex > 0,
  'UPDATE employee SET sex = gender WHERE (sex IS NULL OR sex = "") AND gender IS NOT NULL',
  'SELECT "skip gender->sex sync"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4) 删除遗留列 id_number（存在才删）
SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'employee'
      AND column_name = 'id_number'
  ),
  'ALTER TABLE employee DROP COLUMN id_number',
  'SELECT "skip drop id_number"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5) （可选）保持后续新增一致：若存在触发器则先删再建
DROP TRIGGER IF EXISTS trg_employee_username_sync_before_insert;
DROP TRIGGER IF EXISTS trg_employee_username_sync_before_update;

DELIMITER $$
CREATE TRIGGER trg_employee_username_sync_before_insert
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
  IF (NEW.username IS NULL OR NEW.username = '')
     AND NEW.account IS NOT NULL AND NEW.account <> '' THEN
    SET NEW.username = NEW.account;
  END IF;
END$$

CREATE TRIGGER trg_employee_username_sync_before_update
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
  IF (NEW.username IS NULL OR NEW.username = '')
     AND NEW.account IS NOT NULL AND NEW.account <> '' THEN
    SET NEW.username = NEW.account;
  END IF;
END$$
DELIMITER ;

-- 6) 校验结果（兼容 sex 列可能不存在的情况）
SET @sql = IF(
  @has_sex > 0,
  'SELECT id, account, username, name, phone, gender, sex FROM employee ORDER BY id',
  'SELECT id, account, username, name, phone, gender, NULL AS sex FROM employee ORDER BY id'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
