CREATE TABLE tb_user (
      id                    SERIAL       PRIMARY KEY
    , name                  VARCHAR(100) NOT NULL
    , email                 VARCHAR(255) NOT NULL UNIQUE
    , password              VARCHAR(255) NOT NULL
    , phone                 VARCHAR(15)
    , birth_date            DATE         NOT NULL
    , registration_date     DATE         NOT NULL DEFAULT CURRENT_DATE
    , is_active             BOOLEAN      NOT NULL DEFAULT TRUE
    , is_admin              BOOLEAN      NOT NULL DEFAULT FALSE
);