-- Grao: 1 pessoa (tb_user), unificando os dois perfis de uso.
CREATE TABLE gold.dim_person (
      person_key            SERIAL      PRIMARY KEY
    , user_id               INTEGER     NOT NULL UNIQUE
    , name                  VARCHAR(100) NOT NULL
    , profile_type          VARCHAR(20) NOT NULL
);
