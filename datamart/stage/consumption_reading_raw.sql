CREATE TABLE stage.consumption_reading_raw (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
      CONSTRAINT chk_stage_consumption_reading_raw_volume_liters
        CHECK (volume_liters >= 0)
    , flow_lmin             NUMERIC(10,3) NOT NULL
      CONSTRAINT chk_stage_consumption_reading_raw_flow_lmin
        CHECK (flow_lmin >= 0)
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
