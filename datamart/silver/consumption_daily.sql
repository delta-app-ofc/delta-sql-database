CREATE TABLE silver.consumption_daily (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , consumption_day       DATE          NOT NULL
    , total_liters          NUMERIC(12,3) NOT NULL
    , avg_flow_lmin         NUMERIC(10,3) NOT NULL
    , CONSTRAINT uq_silver_consumption_daily_property_day
        UNIQUE (property_id, consumption_day)
);
