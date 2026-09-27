CREATE TABLE tb_log_property_operational_profile (

      id                    SERIAL PRIMARY KEY

    , property_operational_profile_id INTEGER

    , shift_count           SMALLINT
    , main_water_source     VARCHAR(20)

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT
    , CONSTRAINT fk_tb_log_property_operational_profile_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_property_operational_profile (id)

);
