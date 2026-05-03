-- ========================================================
-- 数据库外键约束最终优化版
-- 原则：保留业务关系，移除无业务 JOIN 的审计约束
-- ========================================================

DELIMITER //

DROP PROCEDURE IF EXISTS fix_fks //
CREATE PROCEDURE fix_fks()
BEGIN
    DECLARE CONTINUE HANDLER FOR 1826 BEGIN END;
    DECLARE CONTINUE HANDLER FOR 1091 BEGIN END; -- Can't DROP, doesn't exist

    -- ====================================================
    -- 〇、先修复列属性（NOT NULL → NULL）
    -- ====================================================
    ALTER TABLE flight_service_rating MODIFY user_id bigint NULL;
    ALTER TABLE flight_service_rating MODIFY flight_id bigint NULL;
    ALTER TABLE meal_selection MODIFY user_id bigint NULL;
    ALTER TABLE meal_selection MODIFY flight_id bigint NULL;

    -- ====================================================
    -- 一、修复 CASCADE → SET NULL（保护分析数据）
    -- ====================================================

    ALTER TABLE recommendation_log DROP FOREIGN KEY fk_recommendation_log_user;
    ALTER TABLE recommendation_log
        ADD CONSTRAINT fk_recommendation_log_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE recommendation_log DROP FOREIGN KEY fk_recommendation_log_flight;
    ALTER TABLE recommendation_log
        ADD CONSTRAINT fk_recommendation_log_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE flight_service_rating DROP FOREIGN KEY fk_rating_user;
    ALTER TABLE flight_service_rating
        ADD CONSTRAINT fk_rating_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE flight_service_rating DROP FOREIGN KEY fk_rating_flight;
    ALTER TABLE flight_service_rating
        ADD CONSTRAINT fk_rating_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE meal_selection DROP FOREIGN KEY fk_meal_selection_user;
    ALTER TABLE meal_selection
        ADD CONSTRAINT fk_meal_selection_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE meal_selection DROP FOREIGN KEY fk_meal_selection_flight;
    ALTER TABLE meal_selection
        ADD CONSTRAINT fk_meal_selection_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    -- ====================================================
    -- 二、移除无业务意义的审计 FK（共 7 条）
    -- ====================================================

    ALTER TABLE dish DROP FOREIGN KEY fk_dish_create_user;
    ALTER TABLE dish DROP FOREIGN KEY fk_dish_update_user;

    ALTER TABLE category DROP FOREIGN KEY fk_category_create_user;
    ALTER TABLE category DROP FOREIGN KEY fk_category_update_user;

    ALTER TABLE flight_info DROP FOREIGN KEY fk_flight_create_user;
    ALTER TABLE flight_info DROP FOREIGN KEY fk_flight_update_user;

    ALTER TABLE flight_announcement DROP FOREIGN KEY fk_flight_announcement_create_user;

END //

DELIMITER ;

CALL fix_fks();
DROP PROCEDURE fix_fks;

-- ====================================================
-- 三、验证最终约束列表（预期 11 条业务 FK）
-- ====================================================
SELECT
    k.TABLE_NAME AS '表',
    r.CONSTRAINT_NAME AS '约束名',
    k.COLUMN_NAME AS '外键列',
    k.REFERENCED_TABLE_NAME AS '引用表',
    r.DELETE_RULE AS '删除规则'
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE k
JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS r
    ON k.CONSTRAINT_SCHEMA = r.CONSTRAINT_SCHEMA
   AND k.CONSTRAINT_NAME   = r.CONSTRAINT_NAME
WHERE k.CONSTRAINT_SCHEMA = 'aviation_food_recommend'
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME;
