CREATE TABLE tb_log_organization (

      id                    SERIAL PRIMARY KEY

    , organization_id       INTEGER

    , corporate_name        VARCHAR(150)
    , trade_name            VARCHAR(150)
    , cnpj                  CHAR(14)
    , business_segment      VARCHAR(20)
    , declared_unit_count   INTEGER
    , registration_date     DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT
    , CONSTRAINT fk_tb_log_organization_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_organization (id)

);
