CREATE TABLE tb_user_habit (
      id                    SERIAL          PRIMARY KEY
    , user_id               INTEGER         NOT NULL
    , habit_id              INTEGER         NOT NULL
    , frequency             INTEGER         NOT NULL
      CONSTRAINT chk_tb_user_habit_frequency
          CHECK (frequency > 0)
    , start_time            TIME
    , end_time              TIME
    , estimated_liters      NUMERIC(6, 2)
      CONSTRAINT chk_tb_user_habit_estimated_liters
          CHECK (estimated_liters IS NULL OR estimated_liters >= 0)
      CONSTRAINT chk_tb_user_habit_time
          CHECK (
              (start_time IS NULL AND end_time IS NULL)
              OR (start_time IS NOT NULL AND end_time IS NOT NULL AND end_time > start_time)
          )
    , CONSTRAINT fk_tb_user_habit_user
        FOREIGN KEY (user_id)
        REFERENCES tb_user (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_user_habit_habit
        FOREIGN KEY (habit_id)
        REFERENCES tb_habit (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);