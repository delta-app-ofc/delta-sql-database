CREATE TABLE tbl_usuario_habito (
      id             SERIAL          PRIMARY KEY
    , id_usuario     INTEGER         NOT NULL
    , id_habito      INTEGER         NOT NULL
    , data_vinculo   TIMESTAMP       DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT fk_usuario_habito_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES tbl_usuario(id)
        ON DELETE CASCADE

    , CONSTRAINT fk_usuario_habito_habito
        FOREIGN KEY (id_habito)
        REFERENCES tbl_habito(id)
        ON DELETE CASCADE

    , CONSTRAINT uq_usuario_habito
        UNIQUE (id_usuario, id_habito)
);