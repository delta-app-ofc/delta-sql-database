CREATE TABLE stage.consumption_summary (
      id                    BIGSERIAL     PRIMARY KEY
    , mongo_id              CHAR(24)      UNIQUE
    , device_id             VARCHAR(100)  NOT NULL
    , user_id               VARCHAR(100)
    , window_started_at     TIMESTAMP     NOT NULL
    , window_finished_at    TIMESTAMP     NOT NULL
    , consumption_liters    NUMERIC(10,3) NOT NULL
      CONSTRAINT chk_stage_consumption_summary_consumption_liters
        CHECK (consumption_liters >= 0)
    , lpm_average           NUMERIC(10,3)
      CONSTRAINT chk_stage_consumption_summary_lpm_average
        CHECK (lpm_average IS NULL OR lpm_average >= 0)
    , anomaly_detected      BOOLEAN
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
