CREATE TABLE tb_log_user_property (

      id                    SERIAL PRIMARY KEY

    , user_property_id      INTEGER
    , user_id               INTEGER
    , property_id           INTEGER
    , association_date      DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

    , CONSTRAINT fk_tb_log_user_property_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_user_property (id)

);