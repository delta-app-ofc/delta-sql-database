CREATE TABLE tbl_habito (
      id        SERIAL          PRIMARY KEY
    , codigo    VARCHAR(50)     NOT NULL UNIQUE
    , descricao TEXT            NOT NULL
);