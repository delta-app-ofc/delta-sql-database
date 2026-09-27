CREATE TABLE tb_water_usage_type (
      id                                          SERIAL      PRIMARY KEY
    , name                                        VARCHAR(30) NOT NULL UNIQUE
      CONSTRAINT chk_tb_water_usage_type_name_values
        CHECK (name IN ('LIMPEZA', 'CONSUMO_HUMANO', 'PROCESSO_PRODUTIVO', 'IRRIGACAO'))
    , description                                 TEXT
);
