CREATE TABLE tb_region (
      id                                   SERIAL      PRIMARY KEY
    , name                                 VARCHAR(20) NOT NULL UNIQUE
      CONSTRAINT chk_tb_region_name_values CHECK (name IN ('LESTE', 'OESTE', 'SUL', 'NORTE', 'CENTRO'))
);