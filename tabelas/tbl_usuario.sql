CREATE TABLE tbl_usuario (
      id               SERIAL          PRIMARY KEY
    , nome             VARCHAR(100)    NOT NULL
    , email            VARCHAR(255)    NOT NULL UNIQUE
    , senha            VARCHAR(255)    NOT NULL
    , telefone         VARCHAR(20)
    , data_nascimento  DATE            NOT NULL
    , data_cadastro    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
    , ativo            BOOLEAN         NOT NULL DEFAULT TRUE
);