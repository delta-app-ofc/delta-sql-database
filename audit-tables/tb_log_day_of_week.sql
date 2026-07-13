CREATE TABLE tb_log_day_of_week (

      id                      SERIAL       PRIMARY KEY

    , day_of_week_id          INTEGER
    , name                    VARCHAR(20)

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_day_of_week_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_day_of_week (id)
);