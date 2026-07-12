CREATE TABLE tb_property (
      id                    SERIAL              PRIMARY KEY
    , name                  VARCHAR(100)        NOT NULL
    , type                  VARCHAR(20)         NOT NULL
      CONSTRAINT chk_tb_property_type           CHECK (type IN ('CASA', 'PRÉDIO'))
    , classification        VARCHAR(20)         NOT NULL
      CONSTRAINT chk_tb_property_classification CHECK (classification IN ('RESIDENCIAL', 'COMERCIAL'))
    , address_id            INTEGER             NOT NULL
    , registration_date     DATE                NOT NULL DEFAULT CURRENT_DATE
    , CONSTRAINT fk_tb_property_address         FOREIGN KEY (address_id)
        REFERENCES tb_address (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);