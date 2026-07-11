CREATE TABLE tb_log_user (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , user_id                 INTEGER
    , name                    VARCHAR(100)
    , email                   VARCHAR(255)
    , password                VARCHAR(255)
    , phone                   VARCHAR(15)
    , birth_date              DATE
    , registration_date       DATE
    , is_active               BOOLEAN
    , is_admin                BOOLEAN
    , is_manager              BOOLEAN
);