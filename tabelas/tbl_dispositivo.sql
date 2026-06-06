CREATE TABLE tbl_dispositivo (
      id                   SERIAL          PRIMARY KEY
    , device_id            VARCHAR(80)    NOT NULL UNIQUE
    , id_instalacao        INTEGER         NOT NULL
    , ativo                BOOLEAN         NOT NULL DEFAULT TRUE
    , data_instalacao      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
    , ultima_comunicacao   TIMESTAMP

    , CONSTRAINT fk_dispositivo_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE
);