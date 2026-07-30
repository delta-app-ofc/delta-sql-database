CREATE TABLE tb_log_device (

      id                    SERIAL PRIMARY KEY

    , device_id_log         INTEGER
    , device_id             INTEGER
    , property_id           INTEGER
    , is_active             BOOLEAN
    , installation_date     DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT
    
    , CONSTRAINT fk_tb_log_device_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_device (id)
);