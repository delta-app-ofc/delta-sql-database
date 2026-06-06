CREATE TABLE tbl_meta_consumo (
      id                     SERIAL          PRIMARY KEY
    , id_instalacao          INTEGER         NOT NULL
    , limite_diario_litros   NUMERIC(10,2)
    , limite_mensal_litros   NUMERIC(10,2)
    , data_inicio            DATE            NOT NULL
    , data_fim               DATE

    , CONSTRAINT fk_meta_consumo_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE

    , CONSTRAINT chk_limite_diario
        CHECK (limite_diario_litros IS NULL OR limite_diario_litros > 0)

    , CONSTRAINT chk_limite_mensal
        CHECK (limite_mensal_litros IS NULL OR limite_mensal_litros > 0)

    , CONSTRAINT chk_periodo_meta
        CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);