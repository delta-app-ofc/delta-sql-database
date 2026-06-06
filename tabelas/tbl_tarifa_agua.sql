CREATE TABLE tbl_tarifa_agua (
      id               SERIAL          PRIMARY KEY
    , cidade           VARCHAR(100)    NOT NULL
    , faixa_inicial    NUMERIC(10,2)   NOT NULL
    , faixa_final      NUMERIC(10,2)   NOT NULL
    , valor_m3         NUMERIC(10,2)   NOT NULL
    , vigencia_inicio  DATE            NOT NULL
    , vigencia_fim     DATE

    , CONSTRAINT chk_faixa_consumo
        CHECK (faixa_inicial >= 0 AND faixa_final > faixa_inicial)

    , CONSTRAINT chk_valor_m3
        CHECK (valor_m3 > 0)

    , CONSTRAINT chk_vigencia
        CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio)
);