CREATE TABLE tb_log_region (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , region_id               INTEGER
    , name                    VARCHAR(20)
);