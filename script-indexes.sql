CREATE INDEX idx_consumption_reading_raw_property_date
    ON stage.consumption_reading_raw (property_id, read_at DESC);

CREATE INDEX idx_gold_dm_property_organization
    ON gold.dm_property (organization_name);
