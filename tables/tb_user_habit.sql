CREATE TABLE tb_user_habit (
      id                    SERIAL      PRIMARY KEY
    , user_id               INTEGER     NOT NULL
    , habit_id              INTEGER     NOT NULL
    , frequency             INTEGER     NOT NULL
      CONSTRAINT chk_tb_user_habit_frequency
          CHECK (frequency > 0)
    , CONSTRAINT uq_tb_user_habit_user_habit
        UNIQUE (user_id, habit_id)
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