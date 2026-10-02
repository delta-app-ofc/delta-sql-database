CREATE TABLE tb_log_property_shift (

      id                    SERIAL PRIMARY KEY

    , property_shift_id     INTEGER

    , property_id           INTEGER
    , start_time            TIME
    , end_time              TIME

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT
    , CONSTRAINT fk_tb_log_property_shift_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_property_shift (id)

);
