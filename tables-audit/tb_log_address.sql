CREATE TABLE tb_log_address (

      id                      SERIAL       PRIMARY KEY

    , address_id              INTEGER
    , region_id               INTEGER
    , cep                     CHAR(8)
    , city                    VARCHAR(60)
    , state                   VARCHAR(30)

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_address_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_address (id)
);