CREATE TABLE tb_address (
      id                            SERIAL      PRIMARY KEY
    , region_id                     INTEGER     NOT NULL
    , cep                           CHAR(8)     NOT NULL
      CONSTRAINT chk_tb_address_cep CHECK      (cep ~ '^[0-9]{8}$')
    , city                          VARCHAR(60) NOT NULL
    , state                         VARCHAR(30) NOT NULL
    , CONSTRAINT uq_tb_address_cep              UNIQUE (cep)
    , CONSTRAINT fk_tb_address_region           FOREIGN KEY (region_id)
        REFERENCES tb_region (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);