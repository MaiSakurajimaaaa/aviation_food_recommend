-- 目的：一次性修复 user 表结构兼容问题（含 id 非自增导致登录失败）
-- 特点：幂等，可重复执行

USE aviation_food_recommend;

-- 0) user 表不存在则按航空版创建
SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = 'user'
  ),
  'SELECT "user table exists"',
  'CREATE TABLE user (
      id INT NOT NULL AUTO_INCREMENT,
      name VARCHAR(64) NULL,
      openid VARCHAR(64) NOT NULL,
      phone VARCHAR(11) NULL,
      gender TINYINT NULL,
      id_number VARCHAR(18) NULL,
      pic LONGTEXT NULL,
      preference_completed INT NULL DEFAULT 0,
      current_flight_id INT NULL,
      create_time DATETIME NULL,
      PRIMARY KEY (id)
    )'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 1) 补齐基础列（缺什么补什么）
SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'name'),
  'SELECT "skip add user.name"',
  'ALTER TABLE user ADD COLUMN name VARCHAR(64) NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'openid'),
  'SELECT "skip add user.openid"',
  'ALTER TABLE user ADD COLUMN openid VARCHAR(64) NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'phone'),
  'SELECT "skip add user.phone"',
  'ALTER TABLE user ADD COLUMN phone VARCHAR(11) NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'gender'),
  'SELECT "skip add user.gender"',
  'ALTER TABLE user ADD COLUMN gender TINYINT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'id_number'),
  'SELECT "skip add user.id_number"',
  'ALTER TABLE user ADD COLUMN id_number VARCHAR(18) NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'pic'),
  'SELECT "skip add user.pic"',
  'ALTER TABLE user ADD COLUMN pic LONGTEXT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'preference_completed'),
  'SELECT "skip add user.preference_completed"',
  'ALTER TABLE user ADD COLUMN preference_completed INT NULL DEFAULT 0'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'current_flight_id'),
  'SELECT "skip add user.current_flight_id"',
  'ALTER TABLE user ADD COLUMN current_flight_id INT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'user' AND column_name = 'create_time'),
  'SELECT "skip add user.create_time"',
  'ALTER TABLE user ADD COLUMN create_time DATETIME NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 修复 id 主键和自增（解决 Field ''id'' doesn''t have a default value）
SET @has_id = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'user'
    AND column_name = 'id'
);

SET @sql = IF(
  @has_id > 0,
  'SELECT "id column exists"',
  'ALTER TABLE user ADD COLUMN id INT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 没有主键时补主键；有主键但不在 id 上时切换到 id
SET @pk_on_id = (
  SELECT COUNT(*)
  FROM information_schema.key_column_usage
  WHERE table_schema = DATABASE()
    AND table_name = 'user'
    AND constraint_name = 'PRIMARY'
    AND column_name = 'id'
);

SET @has_pk = (
  SELECT COUNT(*)
  FROM information_schema.table_constraints
  WHERE table_schema = DATABASE()
    AND table_name = 'user'
    AND constraint_type = 'PRIMARY KEY'
);

SET @sql = IF(
  @has_pk = 0,
  'ALTER TABLE user ADD PRIMARY KEY (id)',
  'SELECT "primary key already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  @has_pk > 0 AND @pk_on_id = 0,
  'ALTER TABLE user DROP PRIMARY KEY, ADD PRIMARY KEY (id)',
  'SELECT "primary key already on id"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 最终把 id 改为自增，并把自增起点设置为 max(id)+1
SET @next_id = (SELECT IFNULL(MAX(id), 0) + 1 FROM user);
SET @sql = CONCAT('ALTER TABLE user MODIFY COLUMN id INT NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=', @next_id);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 校验结果
SELECT
  column_name,
  column_type,
  is_nullable,
  column_default,
  extra
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'user'
  AND column_name IN ('id', 'name', 'openid', 'phone', 'gender', 'id_number', 'pic', 'create_time', 'preference_completed', 'current_flight_id')
ORDER BY column_name;
