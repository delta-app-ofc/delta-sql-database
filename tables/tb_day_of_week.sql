CREATE TABLE tb_day_of_week (
      id                                        SERIAL      PRIMARY KEY
    , name                                      VARCHAR(20) NOT NULL UNIQUE
      CONSTRAINT chk_tb_day_of_week_name_values CHECK (name IN ('SEGUNDA', 'TERÇA', 'QUARTA', 'QUINTA', 'SEXTA', 'SÁBADO', 'DOMINGO'))
);