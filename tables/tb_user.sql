CREATE TABLE tb_user (

      id                    SERIAL PRIMARY KEY

    , name                  VARCHAR(100) NOT NULL
    , email                 VARCHAR(255) UNIQUE NOT NULL
    , phone                 VARCHAR(15) UNIQUE NOT NULL
    , birth_date            DATE NOT NULL

    , registration_date     DATE DEFAULT CURRENT_DATE
    , is_active             BOOLEAN DEFAULT TRUE
    , is_admin              BOOLEAN DEFAULT FALSE
    , is_manager            BOOLEAN DEFAULT FALSE

    , CONSTRAINT ck_tb_user_age_18
        CHECK (birth_date <= CURRENT_DATE - INTERVAL '18 years')
);