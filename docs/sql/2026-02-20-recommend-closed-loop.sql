-- 航空推荐闭环增强（自动选餐 + 提醒触达）

CREATE TABLE IF NOT EXISTS flight_reminder_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  flight_id BIGINT NOT NULL,
  remind_type VARCHAR(10) NOT NULL,
  flight_date VARCHAR(20) NOT NULL,
  create_time DATETIME NOT NULL,
  KEY idx_flight_reminder (flight_id, remind_type, flight_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
