CREATE TABLE gold.fact_consumption_daily (
      fact_key              BIGSERIAL     PRIMARY KEY
    , property_key          INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , total_liters          NUMERIC(12,3) NOT NULL
    , avg_flow_lmin         NUMERIC(10,3) NOT NULL
    , cost_value            NUMERIC(12,2) NOT NULL
    , CONSTRAINT uq_gold_fact_consumption_daily_property_date
        UNIQUE (property_key, date_key)
    , CONSTRAINT fk_gold_fact_consumption_daily_property
        FOREIGN KEY (property_key) REFERENCES gold.dim_property (property_key)
    , CONSTRAINT fk_gold_fact_consumption_daily_date
        FOREIGN KEY (date_key) REFERENCES gold.dim_date (date_key)
);
