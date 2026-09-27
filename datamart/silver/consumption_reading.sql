CREATE TABLE silver.consumption_reading (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
    , flow_lmin             NUMERIC(10,3) NOT NULL
    , CONSTRAINT uq_silver_consumption_reading_property_read_at
        UNIQUE (property_id, read_at)
);
