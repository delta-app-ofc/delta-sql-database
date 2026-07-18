CREATE TABLE tb_log_user_habit_day (

      id                    SERIAL PRIMARY KEY

    , user_habit_day_id     INTEGER
    , user_habit_id         INTEGER
    , day_of_week_id        INTEGER

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

    , CONSTRAINT fk_tb_log_user_habit_day_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_user_habit_day (id)

);