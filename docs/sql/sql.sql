-- =====================================================
-- 增量迁移脚本（可重复执行）
-- 场景：已有基础表，不再重复 create category/dish/... 等全量建表
-- 目标：补齐“航后评分闭环”所需字段与新表
-- =====================================================

-- 1) flight_info 补充航班真实到达与航班状态字段
set @col_exists := (
    select count(1)
    from information_schema.columns
    where table_schema = database()
      and table_name = 'flight_info'
      and column_name = 'actual_arrival_time'
);

set @sql_stmt := if(
    @col_exists = 0,
    'alter table flight_info add column actual_arrival_time datetime null comment ''实际到达时间''',
    'select "actual_arrival_time already exists"'
);

prepare stmt from @sql_stmt;
execute stmt;
deallocate prepare stmt;

set @col_exists := (
    select count(1)
    from information_schema.columns
    where table_schema = database()
      and table_name = 'flight_info'
      and column_name = 'flight_status'
);

set @sql_stmt := if(
    @col_exists = 0,
    'alter table flight_info add column flight_status tinyint default 1 null comment ''航班状态:1计划中,2飞行中,3已到达,4取消''',
    'select "flight_status already exists"'
);

prepare stmt from @sql_stmt;
execute stmt;
deallocate prepare stmt;

-- 2) 新增评分任务表（持久化待评分/延期/提交状态）
create table if not exists flight_service_rating
(
    id               bigint auto_increment primary key,
    user_id          bigint                                not null,
    flight_id        bigint                                not null,
    source_log_id    bigint                                null,
    rating_score     tinyint                               null,
    rating_status    varchar(16) default 'PENDING'        not null,
    first_visible_at datetime                              null,
    last_visible_at  datetime                              null,
    next_remind_at   datetime                              null,
    defer_count      int         default 0                not null,
    submitted_at     datetime                              null,
    expire_at        datetime                              null,
    channel          varchar(16) default 'miniapp'        null,
    create_time      datetime                              null,
    update_time      datetime                              null,
    constraint uk_rating_user_flight unique (user_id, flight_id)
) charset = utf8mb4;

-- 3) 索引：避免重复创建导致报错（1050/1061），使用 information_schema 判断
set @idx_exists := (
    select count(1)
    from information_schema.statistics
    where table_schema = database()
      and table_name = 'flight_service_rating'
      and index_name = 'idx_rating_pending'
);

set @sql_stmt := if(
    @idx_exists = 0,
    'create index idx_rating_pending on flight_service_rating (user_id, rating_status, next_remind_at, expire_at)',
    'select "idx_rating_pending already exists"'
);

prepare stmt from @sql_stmt;
execute stmt;
deallocate prepare stmt;

-- 4) （可选）历史数据回填：把 recommendation_log 的已评分记录同步到任务表
-- 仅在你需要保留历史评分状态时执行；默认注释掉
-- insert into flight_service_rating
-- (user_id, flight_id, source_log_id, rating_score, rating_status, submitted_at, create_time, update_time)
-- select rl.user_id,
--        rl.flight_id,
--        rl.id,
--        rl.user_rating,
--        'SUBMITTED',
--        rl.create_time,
--        now(),
--        now()
-- from recommendation_log rl
-- where rl.user_rating is not null
--   and rl.user_id is not null
--   and rl.flight_id is not null
-- on duplicate key update
--     rating_score = values(rating_score),
--     rating_status = values(rating_status),
--     submitted_at = values(submitted_at),
--     update_time = values(update_time);
