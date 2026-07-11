CREATE TABLE tb_log_day_of_week (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , day_of_week_id          INTEGER
    , name                    VARCHAR(20)
);
