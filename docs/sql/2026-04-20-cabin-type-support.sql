-- 舱型支持：用户舱型 + 航线餐食舱型绑定（经济舱 < 商务舱 < 头等舱）
-- 兼容 MySQL 5.7/8.0（不使用 ADD COLUMN IF NOT EXISTS）

SET @db := DATABASE();

SELECT COUNT(*)
INTO @exists_user_cabin
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @db
  AND TABLE_NAME = 'user'
  AND COLUMN_NAME = 'cabin_type';

SET @sql := IF(
          @exists_user_cabin = 0,
          'ALTER TABLE `user` ADD COLUMN `cabin_type` TINYINT NOT NULL DEFAULT 3 COMMENT ''舱位类型:1头等舱,2商务舱,3经济舱''',
          'SELECT ''skip add user.cabin_type'''
                );
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `user`
SET `cabin_type` = 3
WHERE `cabin_type` IS NULL
    OR `cabin_type` NOT IN (1, 2, 3);

SELECT COUNT(*)
INTO @exists_route_cabin
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @db
  AND TABLE_NAME = 'flight_route_dish'
  AND COLUMN_NAME = 'cabin_type';

SET @sql := IF(
          @exists_route_cabin = 0,
      'ALTER TABLE `flight_route_dish` ADD COLUMN `cabin_type` TINYINT NOT NULL DEFAULT 3 COMMENT ''舱位类型:1头等舱,2商务舱,3经济舱''',
          'SELECT ''skip add flight_route_dish.cabin_type'''
                );
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `flight_route_dish`
SET `cabin_type` = 3
WHERE `cabin_type` IS NULL
  OR `cabin_type` NOT IN (1, 2, 3);

ALTER TABLE `user`
  MODIFY COLUMN `cabin_type` TINYINT NOT NULL DEFAULT 3 COMMENT '舱位类型:1头等舱,2商务舱,3经济舱';

ALTER TABLE `flight_route_dish`
  MODIFY COLUMN `cabin_type` TINYINT NOT NULL DEFAULT 3 COMMENT '舱位类型:1头等舱,2商务舱,3经济舱';
