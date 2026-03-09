USE aviation_food_recommend;

-- 1) 如果 recommendation_log 表不存在，则创建
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

-- 2) 逐个补齐推荐日志所需字段（存在则跳过）
SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'recommendation_log' AND column_name = 'recommended_dishes'
  ),
  'SELECT ''skip recommendation_log.recommended_dishes''',
  'ALTER TABLE recommendation_log ADD COLUMN recommended_dishes JSON NULL AFTER flight_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'recommendation_log' AND column_name = 'algorithm_type'
  ),
  'SELECT ''skip recommendation_log.algorithm_type''',
  'ALTER TABLE recommendation_log ADD COLUMN algorithm_type VARCHAR(50) NULL AFTER recommended_dishes'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'recommendation_log' AND column_name = 'user_feedback'
  ),
  'SELECT ''skip recommendation_log.user_feedback''',
  'ALTER TABLE recommendation_log ADD COLUMN user_feedback VARCHAR(255) NULL AFTER user_rating'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'recommendation_log' AND column_name = 'create_time'
  ),
  'SELECT ''skip recommendation_log.create_time''',
  'ALTER TABLE recommendation_log ADD COLUMN create_time DATETIME NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 检查结构
DESC recommendation_log;

-- 4) dish 增加库存字段（库存为0时自动停用）
SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'dish' AND column_name = 'stock'
  ),
  'SELECT ''skip dish.stock''',
  'ALTER TABLE dish ADD COLUMN stock INT NOT NULL DEFAULT 0 AFTER status'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE dish
SET status = 0
WHERE ifnull(stock, 0) = 0;

-- 5) 删除订单支付字段（免费餐食场景）
SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'orders' AND column_name = 'pay_method'
  ),
  'ALTER TABLE orders DROP COLUMN pay_method',
  'SELECT ''skip orders.pay_method'''
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'orders' AND column_name = 'pay_status'
  ),
  'ALTER TABLE orders DROP COLUMN pay_status',
  'SELECT ''skip orders.pay_status'''
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;