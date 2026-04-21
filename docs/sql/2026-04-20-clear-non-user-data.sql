-- 清库脚本：仅保留 user 表数据，清空其他表数据（保留表结构）
-- 适用：MySQL 5.7 / 8.0
-- 警告：会删除除 user 表外所有表的全部数据，请先备份。

USE aviation_food_recommend;

DROP PROCEDURE IF EXISTS sp_clear_non_user_data;
DELIMITER $$

CREATE PROCEDURE sp_clear_non_user_data()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_table VARCHAR(128);
    DECLARE v_old_fk_checks INT DEFAULT 1;

    DECLARE cur CURSOR FOR
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_type = 'BASE TABLE'
          AND table_name <> 'user'
        ORDER BY table_name;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET FOREIGN_KEY_CHECKS = v_old_fk_checks;
        RESIGNAL;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_name = 'user'
          AND table_type = 'BASE TABLE'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '取消执行：未找到 user 表';
    END IF;

    SET v_old_fk_checks = @@FOREIGN_KEY_CHECKS;
    SET FOREIGN_KEY_CHECKS = 0;

    OPEN cur;
    truncate_loop: LOOP
        FETCH cur INTO v_table;
        IF done = 1 THEN
            LEAVE truncate_loop;
        END IF;

        SET @truncate_sql = CONCAT('TRUNCATE TABLE `', v_table, '`');
        PREPARE stmt FROM @truncate_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE cur;

    SET FOREIGN_KEY_CHECKS = v_old_fk_checks;
END$$
DELIMITER ;

-- 执行清理
CALL sp_clear_non_user_data();

-- 清理临时过程
DROP PROCEDURE IF EXISTS sp_clear_non_user_data;

-- 结果核验（InnoDB 的 table_rows 为估算值，仅用于快速查看）
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT COUNT(*) AS user_row_count FROM `user`;
