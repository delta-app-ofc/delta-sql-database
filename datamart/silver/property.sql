-- Copia tratada de tb_property, ja com o join de tb_address/tb_organization/
-- tb_property_operational_profile resolvido (dado cadastral do proprio
-- Postgres, ja limpo - nao passa por stage). Ainda na chave natural
-- (property_id) - o GOLD e quem monta a chave substituta do star schema.
CREATE TABLE silver.property (
      property_id           INTEGER       PRIMARY KEY
    , name                  VARCHAR(100)  NOT NULL
    , property_type         VARCHAR(20)   NOT NULL
    , classification_id     INTEGER       NOT NULL
    , classification_group  VARCHAR(20)   NOT NULL
    , region_id             INTEGER       NOT NULL
    , city                  VARCHAR(60)   NOT NULL
    , state                 VARCHAR(30)   NOT NULL
    , built_area_m2         NUMERIC(10,2)
    , organization_id       INTEGER
    , organization_name     VARCHAR(150)
    , has_operational_profile BOOLEAN     NOT NULL DEFAULT FALSE
    , shift_count           SMALLINT
    , main_water_source     VARCHAR(20)
);
