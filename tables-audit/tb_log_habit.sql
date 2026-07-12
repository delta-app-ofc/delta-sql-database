CREATE TABLE tb_log_habit (

      id                      SERIAL       PRIMARY KEY

    , habit_id                INTEGER
    , name                    VARCHAR(30)
    , description             TEXT

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_habit_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_habit (id)
);
