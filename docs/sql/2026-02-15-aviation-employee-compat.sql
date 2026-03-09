-- 修复 aviation_food_recommend 与当前 SpringBoot 后端 Employee 模型不一致问题
-- 目标：兼容 fun.hykgraph.entity.Employee + EmployeeMapper 注册/登录 SQL

USE aviation_food_recommend;

-- 0) 确保 employee 表存在（若不存在则创建兼容表）
CREATE TABLE IF NOT EXISTS employee (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(64) NOT NULL DEFAULT '员工',
  account VARCHAR(64) NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(16) NULL,
  age INT NULL,
  gender TINYINT NULL,
  pic LONGTEXT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  create_user INT NOT NULL DEFAULT 100,
  update_user INT NOT NULL DEFAULT 100,
  create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_account (account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1) 若老结构里是 username，则补 account 并迁移值
SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'account'
  ),
  'SELECT "skip employee.account"',
  'ALTER TABLE employee ADD COLUMN account VARCHAR(64) NULL'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'username'
  ),
  'UPDATE employee SET account = username WHERE (account IS NULL OR account = "")',
  'SELECT "skip username->account migrate"'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) 补齐后端需要但新库可能缺失的字段
SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'age'),
  'SELECT "skip employee.age"',
  'ALTER TABLE employee ADD COLUMN age INT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'gender'),
  'SELECT "skip employee.gender"',
  'ALTER TABLE employee ADD COLUMN gender TINYINT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'pic'),
  'SELECT "skip employee.pic"',
  'ALTER TABLE employee ADD COLUMN pic LONGTEXT NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'create_user'),
  'SELECT "skip employee.create_user"',
  'ALTER TABLE employee ADD COLUMN create_user INT NOT NULL DEFAULT 100'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'update_user'),
  'SELECT "skip employee.update_user"',
  'ALTER TABLE employee ADD COLUMN update_user INT NOT NULL DEFAULT 100'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'create_time'),
  'SELECT "skip employee.create_time"',
  'ALTER TABLE employee ADD COLUMN create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'employee' AND column_name = 'update_time'),
  'SELECT "skip employee.update_time"',
  'ALTER TABLE employee ADD COLUMN update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 修正 account 空值并加唯一索引
UPDATE employee
SET account = CONCAT('user_', id)
WHERE account IS NULL OR account = '';

SET @has_uk = (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE() AND table_name = 'employee' AND index_name = 'uk_employee_account'
);
SET @sql = IF(@has_uk > 0, 'SELECT "skip uk_employee_account"', 'ALTER TABLE employee ADD UNIQUE KEY uk_employee_account (account)');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) 尝试保证 id 自增（若原本已是自增则不会有影响）
ALTER TABLE employee MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT;

-- 5) 给注册流程准备一个可测试账号（admin / 123456）
-- 123456 的 md5: e10adc3949ba59abbe56e057f20f883e
INSERT INTO employee (name, account, password, phone, age, gender, status, create_user, update_user)
SELECT '管理员', 'admin', 'e10adc3949ba59abbe56e057f20f883e', '11111111111', 0, 1, 1, 100, 100
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE account = 'admin');
