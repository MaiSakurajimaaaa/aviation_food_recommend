-- 航空推荐系统 MVP 增量脚本（在 aviation_food_recommend 或新库执行）

-- 1) 用户表扩展
SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'user'
      AND column_name = 'preference_completed'
  ),
  'SELECT "skip user.preference_completed"',
  'ALTER TABLE user ADD COLUMN preference_completed TINYINT DEFAULT 0'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'user'
      AND column_name = 'current_flight_id'
  ),
  'SELECT "skip user.current_flight_id"',
  'ALTER TABLE user ADD COLUMN current_flight_id BIGINT NULL'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) 航班表
CREATE TABLE IF NOT EXISTS flight_info (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  flight_number VARCHAR(20),
  departure VARCHAR(50),
  destination VARCHAR(50),
  departure_time DATETIME,
  arrival_time DATETIME,
  duration_minutes INT,
  meal_count TINYINT,
  meal_times JSON,
  selection_deadline DATETIME,
  status TINYINT DEFAULT 1,
  create_user BIGINT,
  update_user BIGINT,
  create_time DATETIME,
  update_time DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'flight_info'
      AND column_name = 'id'
      AND extra LIKE '%auto_increment%'
  ),
  'SELECT "skip flight_info.id auto_increment"',
  'ALTER TABLE flight_info MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3) 航线餐食映射
CREATE TABLE IF NOT EXISTS flight_route_dish (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  departure VARCHAR(50),
  destination VARCHAR(50),
  dish_id BIGINT,
  dish_source TINYINT,
  sort INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4) 用户偏好
CREATE TABLE IF NOT EXISTS user_preference (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,
  meal_type_preferences JSON,
  flavor_preferences JSON,
  allergens JSON,
  dietary_notes VARCHAR(255),
  create_time DATETIME,
  update_time DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5) 推荐日志
CREATE TABLE IF NOT EXISTS recommendation_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,
  flight_id BIGINT,
  recommended_dishes JSON,
  algorithm_type VARCHAR(50),
  user_rating TINYINT,
  user_feedback VARCHAR(255),
  create_time DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6) 航班公告
CREATE TABLE IF NOT EXISTS flight_announcement (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  flight_id BIGINT,
  title VARCHAR(100),
  content TEXT,
  status TINYINT DEFAULT 1,
  create_user BIGINT,
  create_time DATETIME,
  update_time DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7) 预选单（兼容 dashboard 统计）
CREATE TABLE IF NOT EXISTS meal_selection (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  number VARCHAR(50),
  status TINYINT DEFAULT 1,
  user_id BIGINT,
  flight_id BIGINT,
  seat_number VARCHAR(10),
  create_time DATETIME,
  update_time DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8) dish 扩展推荐字段
SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'dish'
      AND column_name = 'meal_type'
  ),
  'SELECT "skip dish.meal_type"',
  'ALTER TABLE dish ADD COLUMN meal_type TINYINT NULL'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'dish'
      AND column_name = 'flavor_tags'
  ),
  'SELECT "skip dish.flavor_tags"',
  'ALTER TABLE dish ADD COLUMN flavor_tags JSON NULL'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
