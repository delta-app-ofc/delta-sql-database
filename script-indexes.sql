CREATE INDEX idx_consumption_reading_raw_property_date
    ON stage.consumption_reading_raw (property_id, read_at DESC);

CREATE INDEX idx_gold_fact_consumption_daily_property_date
    ON gold.fact_consumption_daily (property_key, date_key);

CREATE INDEX idx_gold_fact_water_bill_monthly_person_date
    ON gold.fact_water_bill_monthly (person_key, date_key);

CREATE INDEX idx_gold_dim_property_organization
    ON gold.dim_property (organization_name);
