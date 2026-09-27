CREATE INDEX idx_consumption_reading_raw_property_date
    ON stage.consumption_reading_raw (property_id, read_at DESC);
