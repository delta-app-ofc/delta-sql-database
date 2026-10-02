CREATE TABLE gold.dm_person (
      person_key            SERIAL      PRIMARY KEY
    , user_id               INTEGER     NOT NULL UNIQUE
    , name                  VARCHAR(100) NOT NULL
);
