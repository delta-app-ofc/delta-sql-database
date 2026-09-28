CREATE TABLE silver.ft_consumption_reading (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , device_id             VARCHAR(100)  NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
    , flow_lmin             NUMERIC(10,3) NOT NULL
    , CONSTRAINT uq_silver_ft_consumption_reading_device_read_at
        UNIQUE (device_id, read_at)
);
