CREATE TABLE silver.dm_person (
      user_id               INTEGER     PRIMARY KEY
    , name                  VARCHAR(100) NOT NULL
    , profile_type          VARCHAR(20) NOT NULL
      CONSTRAINT chk_silver_dm_person_profile_type
        CHECK (profile_type IN ('RESIDENCIAL', 'GESTOR'))
);
