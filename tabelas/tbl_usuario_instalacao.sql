CREATE TABLE tbl_usuario_instalacao (
      id               SERIAL          PRIMARY KEY
    , id_usuario       INTEGER         NOT NULL
    , id_instalacao    INTEGER         NOT NULL
    , data_vinculo     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT fk_usuario_instalacao_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES tbl_usuario(id)
        ON DELETE CASCADE

    , CONSTRAINT fk_usuario_instalacao_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE

    , CONSTRAINT uq_usuario_instalacao
        UNIQUE (id_usuario, id_instalacao)
);