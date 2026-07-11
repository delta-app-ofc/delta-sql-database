CREATE TABLE tb_log_address (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , address_id               INTEGER
    , region_id                INTEGER
    , cep                      CHAR(8)
    , city                     VARCHAR(60)
    , state                    VARCHAR(30)
);