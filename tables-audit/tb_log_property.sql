CREATE TABLE tb_log_property (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , property_id             INTEGER
    , name                    VARCHAR(100)
    , type                    VARCHAR(20)
    , classification          VARCHAR(20)
    , address_id              INTEGER
    , registration_date       DATE
);