CREATE TABLE tb_region (
      id                                   SERIAL      PRIMARY KEY
    , name                                 VARCHAR(30) NOT NULL UNIQUE
      CONSTRAINT chk_tb_region_name_values CHECK (name IN ('GRANDE_SP', 'LINS', 'PRESIDENTE_PRUDENTE', 'ADAMANTINA_PIRAPOZINHO', 'BRAGANCA_PAULISTA', 'LITORAL', 'VALE_DO_RIBEIRA', 'INTERIOR', 'VALE_DO_PARAIBA'))
);