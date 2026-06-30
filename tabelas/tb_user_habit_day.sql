CREATE TABLE tb_user_habit_day (
      id                    SERIAL      PRIMARY KEY
    , user_habit_id         INTEGER     NOT NULL
    , day_of_week_id        INTEGER     NOT NULL
    , CONSTRAINT uq_tb_user_habit_day
        UNIQUE (user_habit_id, day_of_week_id)
    , CONSTRAINT fk_tb_user_habit_day_user_habit
        FOREIGN KEY (user_habit_id)
        REFERENCES tb_user_habit (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_user_habit_day_day_of_week
        FOREIGN KEY (day_of_week_id)
        REFERENCES tb_day_of_week (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);