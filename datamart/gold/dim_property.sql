-- Grao: 1 instalacao (residencial ou industrial). Star schema puro: dados
-- de organizacao ficam denormalizados aqui em vez de virar um braco
-- snowflake separado (dim_organization).
CREATE TABLE gold.dim_property (
      property_key            SERIAL      PRIMARY KEY
    , property_id             INTEGER     NOT NULL UNIQUE
    , name                    VARCHAR(100) NOT NULL
    , property_type           VARCHAR(20) NOT NULL
    , classification_group    VARCHAR(20) NOT NULL
    , city                    VARCHAR(60) NOT NULL
    , state                   VARCHAR(30) NOT NULL
    , built_area_m2           NUMERIC(10,2)
    , organization_name       VARCHAR(150)
    , has_operational_profile BOOLEAN     NOT NULL
);
