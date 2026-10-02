CREATE TABLE gold.dm_property (
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
