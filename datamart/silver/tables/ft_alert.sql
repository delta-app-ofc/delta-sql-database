CREATE TABLE silver.ft_alert (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , user_id               INTEGER       NOT NULL
    , device_id             VARCHAR(100)  NOT NULL
    , alert_type            VARCHAR(30)   NOT NULL
    , severity              VARCHAR(10)
    , triggered_at          TIMESTAMP     NOT NULL
    , resolved_at           TIMESTAMP
    , CONSTRAINT uq_silver_ft_alert_device_type_triggered
        UNIQUE (device_id, alert_type, triggered_at)
);
