CREATE TABLE tb_device (
      id                    SERIAL      PRIMARY KEY
    , device_id             VARCHAR(100) NOT NULL UNIQUE
    , property_id           INTEGER      NOT NULL
    , is_active             BOOLEAN      NOT NULL DEFAULT TRUE
    , installation_date     DATE         NOT NULL DEFAULT CURRENT_DATE

    , CONSTRAINT fk_tb_device_property
        FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);