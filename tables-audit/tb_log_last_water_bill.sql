CREATE TABLE tb_log_last_water_bill (

      id                    SERIAL PRIMARY KEY

    , last_water_bill_id    INTEGER
    , user_id               INTEGER
    , month                 DATE
    , total_value           NUMERIC(10,2)
    , m3_value              NUMERIC(10,2)

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);