DELIMITER //

DROP PROCEDURE IF EXISTS add_all_fks //
CREATE PROCEDURE add_all_fks()
BEGIN
    DECLARE CONTINUE HANDLER FOR 1826 BEGIN END;

    -- ======== 1. 餐食域 ========
    ALTER TABLE dish
        ADD CONSTRAINT fk_dish_category
            FOREIGN KEY (category_id) REFERENCES category (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE dish_flavor
        ADD CONSTRAINT fk_dish_flavor_dish
            FOREIGN KEY (dish_id) REFERENCES dish (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    -- ======== 2. 用户域 ========
    ALTER TABLE user_preference
        ADD CONSTRAINT fk_user_preference_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    ALTER TABLE user
        ADD CONSTRAINT fk_user_current_flight
            FOREIGN KEY (current_flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    -- ======== 3. 航班域 ========
    ALTER TABLE flight_announcement
        ADD CONSTRAINT fk_flight_announcement_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    -- ======== 4. 航线-菜品绑定 ========
    ALTER TABLE flight_route_dish
        ADD CONSTRAINT fk_flight_route_dish_dish
            FOREIGN KEY (dish_id) REFERENCES dish (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    -- ======== 5. 餐食预选 ========
    ALTER TABLE meal_selection
        ADD CONSTRAINT fk_meal_selection_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    ALTER TABLE meal_selection
        ADD CONSTRAINT fk_meal_selection_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    -- ======== 6. 推荐日志 ========
    ALTER TABLE recommendation_log
        ADD CONSTRAINT fk_recommendation_log_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    ALTER TABLE recommendation_log
        ADD CONSTRAINT fk_recommendation_log_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    -- ======== 7. 航后评分 ========
    ALTER TABLE flight_service_rating
        ADD CONSTRAINT fk_rating_user
            FOREIGN KEY (user_id) REFERENCES user (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    ALTER TABLE flight_service_rating
        ADD CONSTRAINT fk_rating_flight
            FOREIGN KEY (flight_id) REFERENCES flight_info (id)
            ON UPDATE CASCADE ON DELETE CASCADE;

    -- ======== 8. 审计字段 ========
    ALTER TABLE dish
        ADD CONSTRAINT fk_dish_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL,
        ADD CONSTRAINT fk_dish_update_user
            FOREIGN KEY (update_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE category
        ADD CONSTRAINT fk_category_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL,
        ADD CONSTRAINT fk_category_update_user
            FOREIGN KEY (update_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

    ALTER TABLE flight_info
        ADD CONSTRAINT fk_flight_create_user
            FOREIGN KEY (create_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL,
        ADD CONSTRAINT fk_flight_update_user
            FOREIGN KEY (update_user) REFERENCES employee (id)
            ON UPDATE CASCADE ON DELETE SET NULL;

END //

DELIMITER ;

CALL add_all_fks();
DROP PROCEDURE add_all_fks;
