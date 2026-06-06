CREATE TABLE tbl_instalacao (
      id                   SERIAL          PRIMARY KEY
    , nome_identificador   VARCHAR(100)    NOT NULL
    , tipo_classificacao   VARCHAR(20)     NOT NULL
    , tipo_imovel          VARCHAR(30)     NOT NULL
    , percentual_consumo   NUMERIC(5,2)    NOT NULL
    , cep                  VARCHAR(9)      NOT NULL
    , cidade               VARCHAR(100)    NOT NULL
    , estado               CHAR(2)         NOT NULL
    , data_cadastro        TIMESTAMP       DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT chk_tipo_classificacao
        CHECK (tipo_classificacao IN ('residencial', 'comercial'))

    , CONSTRAINT chk_percentual_consumo
        CHECK (percentual_consumo BETWEEN 0 AND 100)
);