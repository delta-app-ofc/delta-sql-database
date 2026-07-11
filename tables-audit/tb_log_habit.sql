CREATE TABLE tb_log_habit (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , habit_id                INTEGER
    , name                    VARCHAR(30)
    , description             TEXT
);