CREATE TABLE tb_log_device (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , id_device               INTEGER
    , device_id               INTEGER
    , property_id             INTEGER
    , is_active               BOOLEAN
    , installation_date       DATE
);