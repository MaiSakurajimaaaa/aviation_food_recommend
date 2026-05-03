create table category
(
    id          bigint auto_increment
        primary key,
    type        tinyint           null,
    name        varchar(32)       null,
    sort        int               null,
    status      tinyint default 1 null,
    create_time datetime          null,
    update_time datetime          null,
    create_user bigint            null,
    update_user bigint            null
)
    charset = utf8mb4;

create table dish
(
    id          bigint auto_increment
        primary key,
    name        varchar(32)       null,
    category_id bigint            null,
    meal_type   tinyint           null,
    flavor_tags json              null,
    status      tinyint default 1 null,
    stock       int     default 0 not null,
    create_time datetime          null,
    update_time datetime          null,
    create_user bigint            null,
    update_user bigint            null,
    pic         longtext          null,
    detail      varchar(255)      null,
    constraint fk_dish_category
        foreign key (category_id) references category (id)
            on update cascade on delete set null
)
    charset = utf8mb4;

create table dish_flavor
(
    id          bigint auto_increment
        primary key,
    dish_id     bigint       null,
    name        varchar(32)  null,
    value       varchar(200) null,
    create_time datetime     null,
    update_time datetime     null,
    constraint fk_dish_flavor_dish
        foreign key (dish_id) references dish (id)
            on update cascade on delete cascade
)
    charset = utf8mb4;

create table employee
(
    id          bigint auto_increment
        primary key,
    username    varchar(32)       null,
    name        varchar(32)       null,
    password    varchar(64)       null,
    phone       varchar(11)       null,
    sex         varchar(2)        null,
    status      tinyint default 1 null,
    create_time datetime          null,
    update_time datetime          null,
    create_user bigint            null,
    update_user bigint            null,
    account     varchar(64)       null,
    age         int               null,
    gender      tinyint           null,
    pic         longtext          null,
    constraint uk_employee_account
        unique (account)
)
    charset = utf8mb4;

create definer = root@localhost trigger trg_employee_username_sync_before_insert
    before insert
    on employee
    for each row
BEGIN
    IF (NEW.username IS NULL OR NEW.username = '')
        AND NEW.account IS NOT NULL AND NEW.account <> '' THEN
        SET NEW.username = NEW.account;
    END IF;
END;

create definer = root@localhost trigger trg_employee_username_sync_before_update
    before update
    on employee
    for each row
BEGIN
    IF (NEW.username IS NULL OR NEW.username = '')
        AND NEW.account IS NOT NULL AND NEW.account <> '' THEN
        SET NEW.username = NEW.account;
    END IF;
END;

create table flight_info
(
    id                  bigint auto_increment
        primary key,
    flight_number       varchar(20)       null,
    departure           varchar(50)       null,
    destination         varchar(50)       null,
    departure_time      datetime          null,
    arrival_time        datetime          null,
    duration_minutes    int               null,
    meal_count          tinyint           null,
    meal_times          json              null,
    selection_deadline  datetime          null,
    status              tinyint default 1 null,
    create_user         bigint            null,
    update_user         bigint            null,
    create_time         datetime          null,
    update_time         datetime          null,
    actual_arrival_time datetime          null comment '实际到达时间',
    flight_status       tinyint default 1 null comment '航班状态:1计划中,2飞行中,3已到达,4取消'
)
    charset = utf8mb4;

create table flight_announcement
(
    id          bigint auto_increment
        primary key,
    flight_id   bigint            null,
    title       varchar(100)      null,
    content     text              null,
    status      tinyint default 0 null,
    create_user bigint            null,
    create_time datetime          null,
    update_time datetime          null,
    constraint fk_flight_announcement_flight
        foreign key (flight_id) references flight_info (id)
            on update cascade on delete cascade
)
    charset = utf8mb4;

create index idx_flight_number
    on flight_info (flight_number);

create table flight_route_dish
(
    id          bigint auto_increment
        primary key,
    departure   varchar(50)       null,
    destination varchar(50)       null,
    dish_id     bigint            null,
    dish_source tinyint           null,
    sort        int               null,
    cabin_type  tinyint default 3 not null comment '舱位类型:1头等舱,2商务舱,3经济舱',
    constraint fk_flight_route_dish_dish
        foreign key (dish_id) references dish (id)
            on update cascade on delete cascade
)
    charset = utf8mb4;

create table user
(
    id                   bigint auto_increment
        primary key,
    openid               varchar(64)       null,
    phone                varchar(11)       null,
    name                 varchar(32)       null,
    id_number            varchar(255)      null,
    frequent_flyer_no    varchar(32)       null,
    preference_completed tinyint default 0 null,
    current_flight_id    bigint            null,
    create_time          datetime          null,
    update_time          datetime          null,
    gender               tinyint           null,
    pic                  longtext          null,
    cabin_type           tinyint default 3 not null comment '舱位类型:1头等舱,2商务舱,3经济舱',
    constraint fk_user_current_flight
        foreign key (current_flight_id) references flight_info (id)
            on update cascade on delete set null
)
    charset = utf8mb4;

create table flight_service_rating
(
    id               bigint auto_increment
        primary key,
    user_id          bigint                        null,
    flight_id        bigint                        null,
    source_log_id    bigint                        null,
    rating_score     tinyint                       null,
    rating_status    varchar(16) default 'PENDING' not null,
    first_visible_at datetime                      null,
    last_visible_at  datetime                      null,
    next_remind_at   datetime                      null,
    defer_count      int         default 0         not null,
    submitted_at     datetime                      null,
    expire_at        datetime                      null,
    channel          varchar(16) default 'miniapp' null,
    create_time      datetime                      null,
    update_time      datetime                      null,
    constraint uk_rating_user_flight
        unique (user_id, flight_id),
    constraint fk_rating_flight
        foreign key (flight_id) references flight_info (id)
            on update cascade on delete set null,
    constraint fk_rating_user
        foreign key (user_id) references user (id)
            on update cascade on delete set null
)
    charset = utf8mb4;

create index idx_rating_pending
    on flight_service_rating (user_id, rating_status, next_remind_at, expire_at);

create table meal_selection
(
    id          bigint auto_increment
        primary key,
    number      varchar(50)       null,
    status      tinyint default 1 null,
    user_id     bigint            null,
    flight_id   bigint            null,
    meal_order  tinyint default 1 not null,
    seat_number varchar(10)       null,
    create_time datetime          null,
    update_time datetime          null,
    constraint uk_meal_selection_user_flight_order
        unique (user_id, flight_id, meal_order),
    constraint fk_meal_selection_flight
        foreign key (flight_id) references flight_info (id)
            on update cascade on delete set null,
    constraint fk_meal_selection_user
        foreign key (user_id) references user (id)
            on update cascade on delete set null
)
    charset = utf8mb4;

create table recommendation_log
(
    id                 bigint auto_increment
        primary key,
    user_id            bigint       null,
    flight_id          bigint       null,
    recommended_dishes json         null,
    algorithm_type     varchar(50)  null,
    user_rating        tinyint      null,
    user_feedback      varchar(255) null,
    create_time        datetime     null,
    constraint fk_recommendation_log_flight
        foreign key (flight_id) references flight_info (id)
            on update cascade on delete set null,
    constraint fk_recommendation_log_user
        foreign key (user_id) references user (id)
            on update cascade on delete set null
)
    charset = utf8mb4;

create index idx_recommendation_user
    on recommendation_log (user_id);

create index idx_user_openid
    on user (openid);

create table user_preference
(
    id                    bigint auto_increment
        primary key,
    user_id               bigint       null,
    meal_type_preferences json         null,
    flavor_preferences    json         null,
    allergens             json         null,
    dietary_notes         varchar(255) null,
    create_time           datetime     null,
    update_time           datetime     null,
    constraint uk_user_preference_user
        unique (user_id),
    constraint fk_user_preference_user
        foreign key (user_id) references user (id)
            on update cascade on delete cascade
)
    charset = utf8mb4;
UPDATE recommendation_log SET user_rating = NULL
WHERE user_id = 10
  AND user_feedback LIKE 'MANUAL_SELECTED%';

