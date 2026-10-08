CREATE TABLE tb_property (
      id                    SERIAL              PRIMARY KEY
    , name                  VARCHAR(100)        NOT NULL
    , type                  VARCHAR(20)         NOT NULL
      CONSTRAINT chk_tb_property_type           CHECK (type IN ('CASA', 'PRÉDIO'))
    , classification_id     INTEGER             NOT NULL
    , address_id            INTEGER             NOT NULL
    , organization_id       INTEGER
    , built_area_m2         NUMERIC(10,2)
      CONSTRAINT chk_tb_property_built_area_m2
        CHECK (built_area_m2 IS NULL OR built_area_m2 > 0)
    , registration_date     DATE                NOT NULL DEFAULT CURRENT_DATE
    , CONSTRAINT uq_tb_property_name_address    UNIQUE (name, address_id)
    , CONSTRAINT fk_tb_property_classification  FOREIGN KEY (classification_id)
        REFERENCES tb_property_classification (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_property_address         FOREIGN KEY (address_id)
        REFERENCES tb_address (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_property_organization    FOREIGN KEY (organization_id)
        REFERENCES tb_organization (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);