CREATE TABLE gold.dm_user_preference (
      preference_key        SERIAL        PRIMARY KEY
    , person_key            INTEGER       NOT NULL UNIQUE
    , daily_liters_target   INTEGER
    , notifications_enabled BOOLEAN
    , quiet_start_hour      VARCHAR(10)
    , quiet_end_hour        VARCHAR(10)
    , dark_mode_enabled     BOOLEAN       NOT NULL
    , CONSTRAINT fk_gold_dm_user_preference_person
        FOREIGN KEY (person_key) REFERENCES gold.dm_person (person_key)
);
