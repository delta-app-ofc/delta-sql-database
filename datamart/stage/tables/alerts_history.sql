CREATE TABLE stage.alerts_history (
      id                    BIGSERIAL     PRIMARY KEY
    , mongo_id              CHAR(24)      UNIQUE
    , device_id             VARCHAR(100)  NOT NULL
    , user_id               INTEGER       NOT NULL
    , alert_type            VARCHAR(30)   NOT NULL
      CONSTRAINT chk_stage_alerts_history_alert_type
        CHECK (alert_type IN ('vazamento_continuo', 'fluxo_atipico', 'dispositivo_offline', 'leitura_impossivel'))
    , triggered_at          TIMESTAMP     NOT NULL
    , resolved_at           TIMESTAMP
    , severity              VARCHAR(10)
      CONSTRAINT chk_stage_alerts_history_severity
        CHECK (severity IS NULL OR severity IN ('low', 'medium', 'high'))
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
