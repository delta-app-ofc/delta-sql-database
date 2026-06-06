CREATE TABLE tbl_alerta (
      id               SERIAL          PRIMARY KEY
    , id_instalacao    INTEGER         NOT NULL
    , tipo             VARCHAR(30)     NOT NULL
    , mensagem         VARCHAR(500)    NOT NULL
    , status           VARCHAR(20)     NOT NULL DEFAULT 'ativo'
    , data_criacao     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
    , data_resolucao   TIMESTAMP

    , CONSTRAINT fk_alerta_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE

    , CONSTRAINT chk_tipo_alerta
        CHECK (tipo IN ('vazamento', 'consumo_alto', 'consumo_baixo', 'dispositivo_offline'))

    , CONSTRAINT chk_status_alerta
        CHECK (status IN ('ativo', 'resolvido'))

    , CONSTRAINT chk_data_resolucao
        CHECK (data_resolucao IS NULL OR data_resolucao >= data_criacao)
);