-- ========================================================
-- 数据库迁移脚本：从旧版 → 最终版
-- 执行前请备份。可重复执行，已存在的操作自动跳过。
-- ========================================================
USE aviation_food_recommend;

DELIMITER //

DROP PROCEDURE IF EXISTS migrate_to_final //
CREATE PROCEDURE migrate_to_final()
BEGIN
    DECLARE CONTINUE HANDLER FOR 1060 BEGIN END; -- Duplicate column
    DECLARE CONTINUE HANDLER FOR 1091 BEGIN END; -- Can't drop
    DECLARE CONTINUE HANDLER FOR 1826 BEGIN END; -- Duplicate FK
    DECLARE CONTINUE HANDLER FOR 1051 BEGIN END; -- Unknown table
    DECLARE CONTINUE HANDLER FOR 1146 BEGIN END; -- Table doesn't exist

    -- ===== 1. user 表：添加偏好字段 =====
    ALTER TABLE user ADD COLUMN meal_type_preferences json null comment '餐食类型偏好';
    ALTER TABLE user ADD COLUMN flavor_preferences    json null comment '口味偏好';
    ALTER TABLE user ADD COLUMN dietary_notes         varchar(255) null comment '饮食备注';
    ALTER TABLE user ADD COLUMN update_time           datetime null;

    -- ===== 2. 删除冗余列 =====
    ALTER TABLE employee         DROP COLUMN age;
    ALTER TABLE employee         DROP COLUMN sex;
    ALTER TABLE user             DROP COLUMN frequent_flyer_no;
    ALTER TABLE user             DROP COLUMN allergens;
    ALTER TABLE flight_info      DROP COLUMN meal_times;
    ALTER TABLE flight_info      DROP COLUMN flight_status;
    ALTER TABLE flight_info      DROP COLUMN actual_arrival_time;
    ALTER TABLE flight_service_rating DROP COLUMN channel;
    ALTER TABLE meal_selection   DROP COLUMN seat_number;

    -- ===== 3. 删除 dish_flavor 和 user_preference =====

    ALTER TABLE user_preference DROP FOREIGN KEY fk_user_preference_user;
    DROP TABLE user_preference;

    -- ===== 4. flight_route_dish → flight_dish (创建新表) =====
    DROP TABLE IF EXISTS flight_dish;
    CREATE TABLE flight_dish (
        id          bigint auto_increment primary key,
        flight_id   bigint            not null,
        dish_id     bigint            not null,
        cabin_type  tinyint default 3 not null comment '舱位类型',
        sort        int               null,
        create_time datetime          null,
        update_time datetime          null,
        create_user bigint            null,
        update_user bigint            null
    ) charset = utf8mb4;

    INSERT INTO flight_dish (flight_id, dish_id, cabin_type, sort)
    SELECT DISTINCT fi.id, frd.dish_id, frd.cabin_type, frd.sort
    FROM flight_route_dish frd
    JOIN flight_info fi ON fi.departure = frd.departure
                        AND fi.destination = frd.destination;

    DROP TABLE flight_route_dish;

    -- ===== 5. 清理孤立值再补充 FK =====
    UPDATE category           SET create_user = NULL WHERE create_user NOT IN (SELECT id FROM employee);
    UPDATE dish               SET create_user = NULL WHERE create_user NOT IN (SELECT id FROM employee);
    UPDATE flight_info        SET create_user = NULL WHERE create_user NOT IN (SELECT id FROM employee);
    UPDATE flight_announcement SET create_user = NULL WHERE create_user NOT IN (SELECT id FROM employee);

    ALTER TABLE flight_dish
        ADD CONSTRAINT fk_flight_dish_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE CASCADE,
        ADD CONSTRAINT fk_flight_dish_dish
            FOREIGN KEY (dish_id) REFERENCES dish (id)
            ON UPDATE CASCADE ON DELETE CASCADE,
        ADD CONSTRAINT fk_flight_dish_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE category
        ADD CONSTRAINT fk_category_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE dish
        ADD CONSTRAINT fk_dish_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE flight_announcement
        ADD CONSTRAINT fk_flight_announcement_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

END //

DELIMITER ;

CALL migrate_to_final();
DROP PROCEDURE migrate_to_final;

-- ===== 验证 =====
SELECT table_name AS '表名', table_rows AS '行数'
FROM information_schema.tables
WHERE table_schema = 'aviation_food_recommend' AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT COUNT(*) AS '外键总数'
FROM information_schema.referential_constraints
WHERE constraint_schema = 'aviation_food_recommend';
