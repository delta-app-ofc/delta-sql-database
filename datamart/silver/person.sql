-- Unifica tb_user pros dois perfis de uso (residencial e gestor industrial),
-- sem papel/hierarquia entre eles - so marca se a pessoa tem vinculo com
-- alguma organizacao (tb_user_organization) ou nao.
CREATE TABLE silver.person (
      user_id               INTEGER     PRIMARY KEY
    , name                  VARCHAR(100) NOT NULL
    , profile_type          VARCHAR(20) NOT NULL
      CONSTRAINT chk_silver_person_profile_type
        CHECK (profile_type IN ('RESIDENCIAL', 'GESTOR'))
);
