CREATE TABLE tb_habit (
      id                                  SERIAL      PRIMARY KEY
    , name                                VARCHAR(20) NOT NULL UNIQUE
      CONSTRAINT chk_tb_habit_name_values CHECK (name IN ('BANHO LONGO', 'LAVAR QUINTAL', 'LAVAR ROUPA', 'REGAR PLANTAS', 'LAVAR CARRO', 'LAVAR LOUÇA'))
    , description         TEXT
);