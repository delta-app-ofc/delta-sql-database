CREATE TABLE gold.ft_alert (
      alert_key             BIGSERIAL     PRIMARY KEY
    , property_key          INTEGER       NOT NULL
    , person_key            INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , device_id             VARCHAR(100)  NOT NULL
    , alert_type            VARCHAR(30)   NOT NULL
    , severity              VARCHAR(10)
    , triggered_at          TIMESTAMP     NOT NULL
    , resolved_at           TIMESTAMP
    , CONSTRAINT uq_gold_ft_alert_device_type_triggered
        UNIQUE (device_id, alert_type, triggered_at)
    , CONSTRAINT fk_gold_ft_alert_property
        FOREIGN KEY (property_key) REFERENCES gold.dm_property (property_key)
    , CONSTRAINT fk_gold_ft_alert_person
        FOREIGN KEY (person_key) REFERENCES gold.dm_person (person_key)
    , CONSTRAINT fk_gold_ft_alert_date
        FOREIGN KEY (date_key) REFERENCES gold.dm_date (date_key)
);
