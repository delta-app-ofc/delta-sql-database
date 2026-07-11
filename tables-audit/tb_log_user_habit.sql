CREATE TABLE tb_log_user_habit (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , user_habit_id           INTEGER
    , user_id                 INTEGER
    , habit_id                INTEGER
    , frequency               INTEGER
);