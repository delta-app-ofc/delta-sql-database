CREATE TABLE tb_habit (
      id                                      SERIAL      PRIMARY KEY
    , name                                    VARCHAR(30) NOT NULL UNIQUE
      CONSTRAINT chk_tb_habit_name_values     CHECK (name IN ('BANHO LONGO', 'LAVAR QUINTAL', 'LAVAR ROUPA', 'REGAR PLANTAS', 'LAVAR CARRO', 'LAVAR LOUÇA'))
    , category                                VARCHAR(30) NOT NULL
      CONSTRAINT chk_tb_habit_category_values CHECK (category IN ('HIGIENE E CUIDADOS', 'LIMPEZA', 'JARDINAGEM'))
    , description                             TEXT
);