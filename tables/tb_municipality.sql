CREATE TABLE tb_municipality (
      id                                 SERIAL      PRIMARY KEY
    , name                               VARCHAR(60) NOT NULL UNIQUE
    , ibge_code                          INTEGER     NOT NULL UNIQUE
      CONSTRAINT chk_tb_municipality_ibge_code CHECK (ibge_code BETWEEN 3500000 AND 3599999)
    , region_id                          INTEGER     NOT NULL
    , CONSTRAINT fk_tb_municipality_region FOREIGN KEY (region_id)
        REFERENCES tb_region (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);