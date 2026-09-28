CREATE TABLE gold.ft_water_bill_monthly (
      fact_key              BIGSERIAL     PRIMARY KEY
    , person_key            INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
    , m3_value              NUMERIC(10,2) NOT NULL
    , CONSTRAINT uq_gold_ft_water_bill_monthly_person_date
        UNIQUE (person_key, date_key)
    , CONSTRAINT fk_gold_ft_water_bill_monthly_person
        FOREIGN KEY (person_key) REFERENCES gold.dm_person (person_key)
    , CONSTRAINT fk_gold_ft_water_bill_monthly_date
        FOREIGN KEY (date_key) REFERENCES gold.dm_date (date_key)
);
