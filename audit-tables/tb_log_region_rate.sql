CREATE TABLE tb_log_region_rate (

      id                    SERIAL PRIMARY KEY

    , region_rate_id        INTEGER
    , region_id             INTEGER
    , m3_value              NUMERIC(10,2)
    , initial_validity      DATE
    , final_validity        DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

    , CONSTRAINT fk_tb_log_region_rate_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_region_rate (id)

);