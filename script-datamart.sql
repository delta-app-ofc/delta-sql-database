CREATE SCHEMA IF NOT EXISTS stage;

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

CREATE TABLE stage.user_preferences (
      id                    BIGSERIAL     PRIMARY KEY
    , mongo_id              CHAR(24)      UNIQUE
    , user_id               INTEGER       NOT NULL
    , daily_liters_target   INTEGER
    , notifications_enabled BOOLEAN
    , quiet_start_hour      VARCHAR(10)
    , quiet_end_hour        VARCHAR(10)
    , dark_mode_enabled     BOOLEAN       NOT NULL
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

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

CREATE TABLE stage.device_status (
      id                    BIGSERIAL     PRIMARY KEY
    , mongo_id              CHAR(24)      UNIQUE
    , device_id             VARCHAR(100)  NOT NULL
    , last_ping_at          TIMESTAMP
    , wifi_signal_rssi      VARCHAR(20)
    , firmware_version      VARCHAR(50)
    , connectivity_status   VARCHAR(50)   NOT NULL
    , battery_level         SMALLINT
      CONSTRAINT chk_stage_device_status_battery_level
        CHECK (battery_level IS NULL OR battery_level BETWEEN 0 AND 100)
    , unavailability_reason VARCHAR(100)
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE SCHEMA IF NOT EXISTS silver;

CREATE TABLE silver.dm_property (
      property_id           INTEGER       PRIMARY KEY
    , name                  VARCHAR(100)  NOT NULL
    , property_type         VARCHAR(20)   NOT NULL
    , classification_id     INTEGER       NOT NULL
    , classification_group  VARCHAR(20)   NOT NULL
    , region_id             INTEGER       NOT NULL
    , city                  VARCHAR(60)   NOT NULL
    , state                 VARCHAR(30)   NOT NULL
    , built_area_m2         NUMERIC(10,2)
    , organization_id       INTEGER
    , organization_name     VARCHAR(150)
    , has_operational_profile BOOLEAN     NOT NULL DEFAULT FALSE
    , main_water_source     VARCHAR(20)
    , region_name           VARCHAR(60)
    , latitude              NUMERIC(8,6)
    , longitude             NUMERIC(9,6)
    , monthly_target_liters NUMERIC(12,2)
);

CREATE TABLE silver.dm_person (
      user_id               INTEGER     PRIMARY KEY
    , name                  VARCHAR(100) NOT NULL
);

CREATE TABLE silver.ft_consumption_reading (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , device_id             VARCHAR(100)  NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
    , flow_lmin             NUMERIC(10,3) NOT NULL
    , window_minutes        SMALLINT      NOT NULL DEFAULT 10
    , CONSTRAINT uq_silver_ft_consumption_reading_device_read_at
        UNIQUE (device_id, read_at)
);

CREATE TABLE silver.ft_consumption_daily (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , consumption_day       DATE          NOT NULL
    , total_liters          NUMERIC(12,3) NOT NULL
    , avg_flow_lmin         NUMERIC(10,3) NOT NULL
    , CONSTRAINT uq_silver_ft_consumption_daily_property_day
        UNIQUE (property_id, consumption_day)
);

CREATE TABLE silver.ft_water_bill (
      id                    BIGSERIAL     PRIMARY KEY
    , user_id               INTEGER       NOT NULL
    , user_name             VARCHAR(100)  NOT NULL
    , bill_month            DATE          NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
    , m3_value              NUMERIC(10,2) NOT NULL
    , CONSTRAINT uq_silver_ft_water_bill_user_month
        UNIQUE (user_id, bill_month)
);

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

CREATE TABLE silver.dm_user_preference (
      user_id               INTEGER       PRIMARY KEY
    , name                  VARCHAR(100)  NOT NULL
    , daily_liters_target   INTEGER
    , notifications_enabled BOOLEAN
    , quiet_start_hour      VARCHAR(10)
    , quiet_end_hour        VARCHAR(10)
    , dark_mode_enabled     BOOLEAN       NOT NULL
);

CREATE TABLE silver.dm_device_status (
      device_id             VARCHAR(100)  PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , last_ping_at          TIMESTAMP
    , wifi_signal_rssi      VARCHAR(20)
    , firmware_version      VARCHAR(50)
    , connectivity_status   VARCHAR(50)   NOT NULL
    , battery_level         SMALLINT
    , unavailability_reason VARCHAR(100)
    , is_active             BOOLEAN       NOT NULL
);

CREATE OR REPLACE PROCEDURE silver.sp_load_dm_property()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE silver.dm_property;

    INSERT INTO silver.dm_property
    (
          property_id, name, property_type, classification_id, classification_group
        , region_id, city, state, built_area_m2
        , organization_id, organization_name
        , has_operational_profile, main_water_source
        , region_name, latitude, longitude, monthly_target_liters
    )
    SELECT
          p.id
        , p.name
        , p.type
        , p.classification_id
        , pc.group_name
        , a.region_id
        , a.city
        , a.state
        , p.built_area_m2
        , p.organization_id
        , o.trade_name
        , (op.property_id IS NOT NULL)
        , op.main_water_source
        , r.name
        , a.latitude
        , a.longitude
        , g.monthly_target_liters
    FROM tb_property p
    JOIN tb_property_classification pc ON pc.id = p.classification_id
    JOIN tb_address a                  ON a.id = p.address_id
    JOIN tb_region r                   ON r.id = a.region_id
    LEFT JOIN tb_organization o        ON o.id = p.organization_id
    LEFT JOIN tb_property_operational_profile op ON op.property_id = p.id
    LEFT JOIN tb_property_goal g       ON g.property_id = p.id;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_dm_device_status()
LANGUAGE plpgsql
AS $$
BEGIN

    -- Snapshot: guarda só o estado mais recente de cada dispositivo (último ping).
    INSERT INTO silver.dm_device_status
    (
          device_id, property_id, last_ping_at, wifi_signal_rssi, firmware_version
        , connectivity_status, battery_level, unavailability_reason, is_active
    )
    SELECT DISTINCT ON (s.device_id)
          s.device_id
        , d.property_id
        , s.last_ping_at
        , s.wifi_signal_rssi
        , s.firmware_version
        , s.connectivity_status
        , s.battery_level
        , s.unavailability_reason
        , d.is_active
    FROM stage.device_status s
    JOIN tb_device d ON d.device_id = s.device_id
    ORDER BY s.device_id, s.last_ping_at DESC NULLS LAST, s.id DESC
    ON CONFLICT (device_id) DO UPDATE
        SET property_id           = EXCLUDED.property_id
          , last_ping_at          = EXCLUDED.last_ping_at
          , wifi_signal_rssi      = EXCLUDED.wifi_signal_rssi
          , firmware_version      = EXCLUDED.firmware_version
          , connectivity_status   = EXCLUDED.connectivity_status
          , battery_level         = EXCLUDED.battery_level
          , unavailability_reason = EXCLUDED.unavailability_reason
          , is_active             = EXCLUDED.is_active;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_dm_person()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE silver.dm_person;

    INSERT INTO silver.dm_person (user_id, name)
    SELECT id, name
    FROM tb_user;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_ft_consumption_reading()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.ft_consumption_reading (property_id, device_id, read_at, volume_liters, flow_lmin, window_minutes)
    SELECT
          d.property_id
        , s.device_id
        , s.window_started_at
        , s.consumption_liters
        , COALESCE(s.lpm_average, 0)
        , GREATEST(1, ROUND(EXTRACT(EPOCH FROM (s.window_finished_at - s.window_started_at)) / 60.0))::SMALLINT
    FROM stage.consumption_summary s
    JOIN tb_device d ON d.device_id = s.device_id
    ON CONFLICT (device_id, read_at) DO NOTHING;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_ft_consumption_daily()
LANGUAGE plpgsql
AS $$
BEGIN

    WITH daily AS (
        SELECT
              property_id
            , DATE(read_at)       AS consumption_day
            , SUM(volume_liters)  AS total_liters
            , AVG(flow_lmin)      AS avg_flow_lmin
        FROM silver.ft_consumption_reading
        GROUP BY property_id, DATE(read_at)
    )
    INSERT INTO silver.ft_consumption_daily (property_id, consumption_day, total_liters, avg_flow_lmin)
    SELECT property_id, consumption_day, total_liters, avg_flow_lmin
    FROM daily
    ON CONFLICT (property_id, consumption_day) DO UPDATE
        SET total_liters  = EXCLUDED.total_liters
          , avg_flow_lmin = EXCLUDED.avg_flow_lmin;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_ft_water_bill()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.ft_water_bill (user_id, user_name, bill_month, total_value, m3_value)
    SELECT b.user_id, u.name, b.month, b.total_value, b.m3_value
    FROM tb_last_water_bill b
    JOIN tb_user u ON u.id = b.user_id
    ON CONFLICT (user_id, bill_month) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value     = EXCLUDED.m3_value;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_ft_alert()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.ft_alert (property_id, user_id, device_id, alert_type, severity, triggered_at, resolved_at)
    SELECT
          d.property_id
        , a.user_id
        , a.device_id
        , a.alert_type
        , a.severity
        , a.triggered_at
        , a.resolved_at
    FROM stage.alerts_history a
    JOIN tb_device d ON d.device_id = a.device_id
    ON CONFLICT (device_id, alert_type, triggered_at) DO UPDATE
        SET severity    = EXCLUDED.severity
          , resolved_at = EXCLUDED.resolved_at;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load_dm_user_preference()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.dm_user_preference
    (
          user_id, name, daily_liters_target, notifications_enabled
        , quiet_start_hour, quiet_end_hour, dark_mode_enabled
    )
    SELECT
          p.user_id
        , u.name
        , p.daily_liters_target
        , p.notifications_enabled
        , p.quiet_start_hour
        , p.quiet_end_hour
        , p.dark_mode_enabled
    FROM stage.user_preferences p
    JOIN tb_user u ON u.id = p.user_id
    ON CONFLICT (user_id) DO UPDATE
        SET name                  = EXCLUDED.name
          , daily_liters_target   = EXCLUDED.daily_liters_target
          , notifications_enabled = EXCLUDED.notifications_enabled
          , quiet_start_hour      = EXCLUDED.quiet_start_hour
          , quiet_end_hour        = EXCLUDED.quiet_end_hour
          , dark_mode_enabled     = EXCLUDED.dark_mode_enabled;

END;
$$;

CREATE OR REPLACE PROCEDURE silver.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    CALL silver.sp_load_ft_consumption_reading();
    CALL silver.sp_load_ft_consumption_daily();
    CALL silver.sp_load_ft_alert();
    CALL silver.sp_load_dm_property();
    CALL silver.sp_load_dm_person();
    CALL silver.sp_load_ft_water_bill();
    CALL silver.sp_load_dm_user_preference();
    CALL silver.sp_load_dm_device_status();

END;
$$;

CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE gold.dm_date (
      date_key              INTEGER     PRIMARY KEY
    , full_date             DATE        NOT NULL UNIQUE
    , day_of_week           SMALLINT    NOT NULL
    , day_name              VARCHAR(20) NOT NULL
    , week_of_year          SMALLINT    NOT NULL
    , month_number          SMALLINT    NOT NULL
    , quarter_number        SMALLINT    NOT NULL
    , year_number           SMALLINT    NOT NULL
    , is_weekend            BOOLEAN     NOT NULL
);

CREATE TABLE gold.dm_property (
      property_key            SERIAL      PRIMARY KEY
    , property_id             INTEGER     NOT NULL UNIQUE
    , name                    VARCHAR(100) NOT NULL
    , property_type           VARCHAR(20) NOT NULL
    , classification_group    VARCHAR(20) NOT NULL
    , city                    VARCHAR(60) NOT NULL
    , state                   VARCHAR(30) NOT NULL
    , built_area_m2           NUMERIC(10,2)
    , organization_name       VARCHAR(150)
    , has_operational_profile BOOLEAN     NOT NULL
    , organization_id         INTEGER
    , region_name             VARCHAR(60)
    , latitude                NUMERIC(8,6)
    , longitude               NUMERIC(9,6)
    , monthly_target_liters   NUMERIC(12,2)
);

CREATE TABLE gold.dm_person (
      person_key            SERIAL      PRIMARY KEY
    , user_id               INTEGER     NOT NULL UNIQUE
    , name                  VARCHAR(100) NOT NULL
);

CREATE TABLE gold.ft_consumption_daily (
      fact_key              BIGSERIAL     PRIMARY KEY
    , property_key          INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , total_liters          NUMERIC(12,3) NOT NULL
    , avg_flow_lmin         NUMERIC(10,3) NOT NULL
    , cost_value            NUMERIC(12,2) NOT NULL
    , CONSTRAINT uq_gold_ft_consumption_daily_property_date
        UNIQUE (property_key, date_key)
    , CONSTRAINT fk_gold_ft_consumption_daily_property
        FOREIGN KEY (property_key) REFERENCES gold.dm_property (property_key)
    , CONSTRAINT fk_gold_ft_consumption_daily_date
        FOREIGN KEY (date_key) REFERENCES gold.dm_date (date_key)
);

CREATE TABLE gold.ft_consumption_reading (
      reading_key           BIGSERIAL     PRIMARY KEY
    , property_key          INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , device_id             VARCHAR(100)  NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
    , flow_lmin             NUMERIC(10,3) NOT NULL
    , window_minutes        SMALLINT      NOT NULL
    , CONSTRAINT uq_gold_ft_consumption_reading_device_read_at
        UNIQUE (device_id, read_at)
    , CONSTRAINT fk_gold_ft_consumption_reading_property
        FOREIGN KEY (property_key) REFERENCES gold.dm_property (property_key)
    , CONSTRAINT fk_gold_ft_consumption_reading_date
        FOREIGN KEY (date_key) REFERENCES gold.dm_date (date_key)
);

CREATE TABLE gold.dm_device_status (
      device_key            SERIAL        PRIMARY KEY
    , device_id             VARCHAR(100)  NOT NULL UNIQUE
    , property_key          INTEGER       NOT NULL
    , last_ping_at          TIMESTAMP
    , wifi_signal_rssi      VARCHAR(20)
    , firmware_version      VARCHAR(50)
    , connectivity_status   VARCHAR(50)   NOT NULL
    , battery_level         SMALLINT
    , unavailability_reason VARCHAR(100)
    , is_active             BOOLEAN       NOT NULL
    , CONSTRAINT fk_gold_dm_device_status_property
        FOREIGN KEY (property_key) REFERENCES gold.dm_property (property_key)
);

CREATE TABLE gold.ft_water_bill_monthly (
      fact_key              BIGSERIAL     PRIMARY KEY
    , person_key            INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
    , m3_value              NUMERIC(10,2) NOT NULL
    , CONSTRAINT uq_gold_ft_water_bill_monthly_person_date
        UNIQUE (person_key, date_key)
    , CONSTRAINT fk_gold_ft_water_bill_monthly_person
        FOREIGN KEY (person_key) REFERENCES gold.dm_person (person_key)
    , CONSTRAINT fk_gold_ft_water_bill_monthly_date
        FOREIGN KEY (date_key) REFERENCES gold.dm_date (date_key)
);

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

CREATE TABLE gold.dm_user_preference (
      preference_key        SERIAL        PRIMARY KEY
    , person_key            INTEGER       NOT NULL UNIQUE
    , daily_liters_target   INTEGER
    , notifications_enabled BOOLEAN
    , quiet_start_hour      VARCHAR(10)
    , quiet_end_hour        VARCHAR(10)
    , dark_mode_enabled     BOOLEAN       NOT NULL
    , CONSTRAINT fk_gold_dm_user_preference_person
        FOREIGN KEY (person_key) REFERENCES gold.dm_person (person_key)
);

CREATE TABLE gold.ft_investment_scenario (
      scenario_key          SERIAL        PRIMARY KEY
    , scenario_id           INTEGER       NOT NULL UNIQUE
    , organization_id       INTEGER
    , name                  VARCHAR(100)  NOT NULL
    , investment_value      NUMERIC(10,2) NOT NULL
    , reduction_pct         NUMERIC(5,2)  NOT NULL
    , annual_savings_value  NUMERIC(10,2) NOT NULL
    , payback_months        NUMERIC(6,1)
);

CREATE OR REPLACE PROCEDURE gold.sp_load_dm_date()
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_date DATE;
    v_max_date DATE;
BEGIN

    -- Intervalo de referência (5 anos pra trás, 2 pra frente) combinado com as datas
    -- reais que já existem na Silver - nunca deixa a dimensão mais curta que o dado real.
    SELECT
          LEAST(CURRENT_DATE - INTERVAL '5 years', MIN(d))::DATE
        , GREATEST(CURRENT_DATE + INTERVAL '2 years', MAX(d))::DATE
      INTO v_min_date, v_max_date
      FROM (
          SELECT consumption_day AS d FROM silver.ft_consumption_daily
          UNION ALL
          SELECT bill_month      AS d FROM silver.ft_water_bill
      ) datas;

    INSERT INTO gold.dm_date (date_key, full_date, day_of_week, day_name, week_of_year, month_number, quarter_number, year_number, is_weekend)
    SELECT
          TO_CHAR(d, 'YYYYMMDD')::INTEGER
        , d
        , EXTRACT(DOW FROM d)
        , TRIM(TO_CHAR(d, 'Day'))
        , EXTRACT(WEEK FROM d)
        , EXTRACT(MONTH FROM d)
        , EXTRACT(QUARTER FROM d)
        , EXTRACT(YEAR FROM d)
        , EXTRACT(DOW FROM d) IN (0, 6)
    FROM generate_series(v_min_date, v_max_date, INTERVAL '1 day') AS d
    ON CONFLICT (date_key) DO NOTHING;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_dm_property()
LANGUAGE plpgsql
AS $$
BEGIN

    -- Nunca remove uma propriedade que ainda tem fato vinculado (preserva histórico) -
    -- só limpa dimensão órfã sem nenhum dado de consumo associado.
    DELETE FROM gold.dm_property
    WHERE property_id NOT IN (SELECT property_id FROM silver.dm_property)
      AND property_key NOT IN (SELECT property_key FROM gold.ft_consumption_daily);

    INSERT INTO gold.dm_property
    (
          property_id, name, property_type, classification_group, city, state, built_area_m2
        , organization_name, has_operational_profile
        , organization_id, region_name, latitude, longitude, monthly_target_liters
    )
    SELECT
          property_id, name, property_type, classification_group, city, state, built_area_m2
        , organization_name, has_operational_profile
        , organization_id, region_name, latitude, longitude, monthly_target_liters
    FROM silver.dm_property
    ON CONFLICT (property_id) DO UPDATE
        SET name                     = EXCLUDED.name
          , property_type            = EXCLUDED.property_type
          , classification_group     = EXCLUDED.classification_group
          , city                     = EXCLUDED.city
          , state                    = EXCLUDED.state
          , built_area_m2            = EXCLUDED.built_area_m2
          , organization_name        = EXCLUDED.organization_name
          , has_operational_profile  = EXCLUDED.has_operational_profile
          , organization_id          = EXCLUDED.organization_id
          , region_name              = EXCLUDED.region_name
          , latitude                 = EXCLUDED.latitude
          , longitude                = EXCLUDED.longitude
          , monthly_target_liters    = EXCLUDED.monthly_target_liters;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_ft_consumption_reading()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_consumption_reading (property_key, date_key, device_id, read_at, volume_liters, flow_lmin, window_minutes)
    SELECT
          dp.property_key
        , TO_CHAR(r.read_at, 'YYYYMMDD')::INTEGER
        , r.device_id
        , r.read_at
        , r.volume_liters
        , r.flow_lmin
        , r.window_minutes
    FROM silver.ft_consumption_reading r
    JOIN gold.dm_property dp ON dp.property_id = r.property_id
    JOIN gold.dm_date     dd ON dd.date_key    = TO_CHAR(r.read_at, 'YYYYMMDD')::INTEGER
    ON CONFLICT (device_id, read_at) DO NOTHING;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_dm_device_status()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.dm_device_status
    (
          device_id, property_key, last_ping_at, wifi_signal_rssi, firmware_version
        , connectivity_status, battery_level, unavailability_reason, is_active
    )
    SELECT
          s.device_id
        , dp.property_key
        , s.last_ping_at
        , s.wifi_signal_rssi
        , s.firmware_version
        , s.connectivity_status
        , s.battery_level
        , s.unavailability_reason
        , s.is_active
    FROM silver.dm_device_status s
    JOIN gold.dm_property dp ON dp.property_id = s.property_id
    ON CONFLICT (device_id) DO UPDATE
        SET property_key          = EXCLUDED.property_key
          , last_ping_at          = EXCLUDED.last_ping_at
          , wifi_signal_rssi      = EXCLUDED.wifi_signal_rssi
          , firmware_version      = EXCLUDED.firmware_version
          , connectivity_status   = EXCLUDED.connectivity_status
          , battery_level         = EXCLUDED.battery_level
          , unavailability_reason = EXCLUDED.unavailability_reason
          , is_active             = EXCLUDED.is_active;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_dm_person()
LANGUAGE plpgsql
AS $$
BEGIN

    -- Nunca remove uma pessoa que ainda tem fato vinculado (preserva histórico) -
    -- só limpa dimensão órfã sem nenhuma fatura associada.
    DELETE FROM gold.dm_person
    WHERE user_id NOT IN (SELECT user_id FROM silver.dm_person)
      AND person_key NOT IN (SELECT person_key FROM gold.ft_water_bill_monthly);

    INSERT INTO gold.dm_person (user_id, name)
    SELECT user_id, name
    FROM silver.dm_person
    ON CONFLICT (user_id) DO UPDATE
        SET name = EXCLUDED.name;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_ft_consumption_daily()
LANGUAGE plpgsql
AS $$
BEGIN

    WITH staging_daily AS (
        SELECT
              cd.property_id
            , cd.consumption_day
            , cd.total_liters
            , cd.avg_flow_lmin
            , sp.region_id
            , sp.classification_id
        FROM silver.ft_consumption_daily cd
        JOIN silver.dm_property sp ON sp.property_id = cd.property_id
    ),
    with_cost AS (
        SELECT
              sd.*
            , ROUND(sd.total_liters / 1000.0 * r.m3_value, 2) AS cost_value
        FROM staging_daily sd
        JOIN LATERAL (
            SELECT rr.m3_value
              FROM tb_region_rate rr
             WHERE rr.region_id = sd.region_id
               AND rr.classification_id = sd.classification_id
               AND rr.initial_validity <= sd.consumption_day
               AND (rr.final_validity IS NULL OR rr.final_validity >= sd.consumption_day)
             ORDER BY rr.initial_validity DESC
             LIMIT 1
        ) r ON TRUE
    )
    INSERT INTO gold.ft_consumption_daily (property_key, date_key, total_liters, avg_flow_lmin, cost_value)
    SELECT
          dp.property_key
        , TO_CHAR(wc.consumption_day, 'YYYYMMDD')::INTEGER
        , wc.total_liters
        , wc.avg_flow_lmin
        , wc.cost_value
    FROM with_cost wc
    JOIN gold.dm_property dp ON dp.property_id = wc.property_id
    ON CONFLICT (property_key, date_key) DO UPDATE
        SET total_liters  = EXCLUDED.total_liters
          , avg_flow_lmin = EXCLUDED.avg_flow_lmin
          , cost_value    = EXCLUDED.cost_value;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_ft_water_bill_monthly()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_water_bill_monthly (person_key, date_key, total_value, m3_value)
    SELECT
          dp.person_key
        , TO_CHAR(wb.bill_month, 'YYYYMMDD')::INTEGER
        , wb.total_value
        , wb.m3_value
    FROM silver.ft_water_bill wb
    JOIN gold.dm_person dp ON dp.user_id = wb.user_id
    ON CONFLICT (person_key, date_key) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value    = EXCLUDED.m3_value;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_ft_investment_scenario()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_investment_scenario (scenario_id, organization_id, name, investment_value, reduction_pct, annual_savings_value, payback_months)
    SELECT id, organization_id, name, investment_value, reduction_pct, annual_savings_value, payback_months
    FROM tb_investment_scenario
    ON CONFLICT (scenario_id) DO UPDATE
        SET organization_id      = EXCLUDED.organization_id
          , name                 = EXCLUDED.name
          , investment_value     = EXCLUDED.investment_value
          , reduction_pct        = EXCLUDED.reduction_pct
          , annual_savings_value = EXCLUDED.annual_savings_value
          , payback_months       = EXCLUDED.payback_months;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_ft_alert()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_alert (property_key, person_key, date_key, device_id, alert_type, severity, triggered_at, resolved_at)
    SELECT
          dp.property_key
        , dpe.person_key
        , TO_CHAR(a.triggered_at, 'YYYYMMDD')::INTEGER
        , a.device_id
        , a.alert_type
        , a.severity
        , a.triggered_at
        , a.resolved_at
    FROM silver.ft_alert a
    JOIN gold.dm_property dp  ON dp.property_id = a.property_id
    JOIN gold.dm_person   dpe ON dpe.user_id    = a.user_id
    JOIN gold.dm_date     dd  ON dd.date_key    = TO_CHAR(a.triggered_at, 'YYYYMMDD')::INTEGER
    ON CONFLICT (device_id, alert_type, triggered_at) DO UPDATE
        SET severity    = EXCLUDED.severity
          , resolved_at = EXCLUDED.resolved_at;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load_dm_user_preference()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.dm_user_preference
    (
          person_key, daily_liters_target, notifications_enabled
        , quiet_start_hour, quiet_end_hour, dark_mode_enabled
    )
    SELECT
          dpe.person_key
        , up.daily_liters_target
        , up.notifications_enabled
        , up.quiet_start_hour
        , up.quiet_end_hour
        , up.dark_mode_enabled
    FROM silver.dm_user_preference up
    JOIN gold.dm_person dpe ON dpe.user_id = up.user_id
    ON CONFLICT (person_key) DO UPDATE
        SET daily_liters_target   = EXCLUDED.daily_liters_target
          , notifications_enabled = EXCLUDED.notifications_enabled
          , quiet_start_hour      = EXCLUDED.quiet_start_hour
          , quiet_end_hour        = EXCLUDED.quiet_end_hour
          , dark_mode_enabled     = EXCLUDED.dark_mode_enabled;

END;
$$;

CREATE OR REPLACE PROCEDURE gold.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    CALL gold.sp_load_dm_date();
    CALL gold.sp_load_dm_property();
    CALL gold.sp_load_dm_person();
    CALL gold.sp_load_ft_consumption_daily();
    CALL gold.sp_load_ft_consumption_reading();
    CALL gold.sp_load_dm_device_status();
    CALL gold.sp_load_ft_water_bill_monthly();
    CALL gold.sp_load_ft_investment_scenario();
    CALL gold.sp_load_ft_alert();
    CALL gold.sp_load_dm_user_preference();

END;
$$;

CREATE SCHEMA IF NOT EXISTS dw;

CREATE OR REPLACE VIEW dw.vw_ft_consumption_daily AS
WITH staging_consumption AS (
    SELECT
          f.property_key
        , dp.property_id
        , dp.name           AS property_name
        , dd.full_date
        , f.total_liters
        , f.cost_value
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    JOIN gold.dm_date dd     ON dd.date_key = f.date_key
)
SELECT
      property_id
    , property_name
    , full_date
    , total_liters
    , cost_value
    , SUM(total_liters) OVER (
          PARTITION BY property_id ORDER BY full_date
          ROWS UNBOUNDED PRECEDING
      ) AS running_total_liters
    , AVG(total_liters) OVER (
          PARTITION BY property_id ORDER BY full_date
          ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ) AS moving_avg_7d_liters
FROM staging_consumption;

CREATE OR REPLACE VIEW dw.vw_ft_property_ranking AS
WITH agg_consumption AS (
    SELECT
          dp.property_id
        , dp.name             AS property_name
        , dp.built_area_m2
        , SUM(f.total_liters) AS total_liters
        , SUM(f.cost_value)   AS total_cost
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    WHERE dp.built_area_m2 IS NOT NULL
    GROUP BY dp.property_id, dp.name, dp.built_area_m2
),
final_ranking AS (
    SELECT
          property_id
        , property_name
        , total_liters
        , total_cost
        , ROUND(total_liters / built_area_m2, 2) AS liters_per_m2
    FROM agg_consumption
)
SELECT
      property_id
    , property_name
    , total_liters
    , total_cost
    , liters_per_m2
    , RANK()         OVER (ORDER BY liters_per_m2 ASC)  AS rank_efficiency
    , DENSE_RANK()   OVER (ORDER BY total_cost DESC)    AS rank_cost
    , NTILE(4)       OVER (ORDER BY liters_per_m2)      AS consumption_quartile
    , PERCENT_RANK() OVER (ORDER BY liters_per_m2)      AS consumption_percent_rank
FROM final_ranking;

CREATE OR REPLACE VIEW dw.vw_ft_monthly_variation AS
WITH staging_monthly AS (
    SELECT
          dp.property_id
        , dp.name AS property_name
        , DATE_TRUNC('month', dd.full_date)::DATE AS reference_month
        , SUM(f.total_liters) AS total_liters
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    JOIN gold.dm_date dd     ON dd.date_key = f.date_key
    GROUP BY dp.property_id, dp.name, DATE_TRUNC('month', dd.full_date)
),
final_variation AS (
    SELECT
          property_id
        , property_name
        , reference_month
        , total_liters
        , LAG(total_liters) OVER (PARTITION BY property_id ORDER BY reference_month) AS previous_month_liters
    FROM staging_monthly
)
SELECT
      property_id
    , property_name
    , reference_month
    , total_liters
    , previous_month_liters
    , ROUND(
          (total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100
        , 1
      ) AS variation_pct
FROM final_variation;

CREATE OR REPLACE VIEW dw.vw_ft_consumption_distribution AS
WITH staging_daily_totals AS (
    SELECT
          f.property_key
        , f.total_liters
    FROM gold.ft_consumption_daily f
),
agg_stats AS (
    SELECT
          MIN(total_liters) AS min_liters
        , MAX(total_liters) AS max_liters
        , PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_liters) AS q1_liters
        , PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_liters) AS median_liters
        , PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_liters) AS q3_liters
    FROM staging_daily_totals
)
SELECT
      s.property_key
    , s.total_liters
    , NTILE(5) OVER (ORDER BY s.total_liters) AS distribution_bucket
    , a.min_liters
    , a.q1_liters
    , a.median_liters
    , a.q3_liters
    , a.max_liters
FROM staging_daily_totals s
CROSS JOIN agg_stats a;

CREATE OR REPLACE VIEW dw.vw_ft_capex_comparison AS
WITH staging_scenario AS (
    SELECT
          fact.scenario_id
        , scenario.name
        , fact.investment_value
        , fact.reduction_pct
        , fact.annual_savings_value
        , fact.payback_months
    FROM gold.ft_investment_scenario AS fact
    INNER JOIN tb_investment_scenario AS scenario
        ON scenario.id = fact.scenario_id
    WHERE UPPER(scenario.name) NOT LIKE 'SIMULACAO DASH%'
      AND UPPER(scenario.name) NOT LIKE 'SIMULAÇÃO DASH%'
)
SELECT
      scenario_id
    , name
    , investment_value
    , reduction_pct
    , annual_savings_value
    , payback_months
    , RANK() OVER (ORDER BY payback_months ASC NULLS LAST) AS rank_by_payback
FROM staging_scenario;

CREATE OR REPLACE VIEW dw.vw_ft_residential_efficiency_ranking AS
WITH staging_bill AS (
    SELECT
          dpe.user_id
        , dpe.name AS person_name
        , dd.full_date AS reference_month
        , f.m3_value
        , f.total_value
    FROM gold.ft_water_bill_monthly f
    JOIN gold.dm_person dpe ON dpe.person_key = f.person_key
    JOIN gold.dm_date dd    ON dd.date_key = f.date_key
)
SELECT
      user_id
    , person_name
    , reference_month
    , m3_value
    , total_value
    , RANK()         OVER (PARTITION BY reference_month ORDER BY m3_value ASC) AS rank_efficiency
    , PERCENT_RANK() OVER (PARTITION BY reference_month ORDER BY m3_value)     AS consumption_percent_rank
FROM staging_bill;

CREATE OR REPLACE VIEW dw.vw_audit_history_chain AS
WITH RECURSIVE chain AS (
    SELECT
          id
        , region_rate_id
        , m3_value
        , operation
        , executed_by
        , executed_at
        , previous_log_id
        , 1 AS level
    FROM tb_log_region_rate
    WHERE previous_log_id IS NULL

    UNION ALL

    SELECT
          l.id
        , l.region_rate_id
        , l.m3_value
        , l.operation
        , l.executed_by
        , l.executed_at
        , l.previous_log_id
        , c.level + 1
    FROM tb_log_region_rate l
    JOIN chain c ON l.previous_log_id = c.id
)
SELECT
      id AS log_id
    , region_rate_id
    , m3_value
    , operation
    , executed_by
    , executed_at
    , level
FROM chain;

CREATE OR REPLACE VIEW dw.vw_ft_alert AS
SELECT
      fa.alert_key
    , dp.property_id
    , dp.name           AS property_name
    , dpe.user_id
    , dpe.name          AS person_name
    , dd.full_date      AS alert_date
    , fa.device_id
    , fa.alert_type
    , fa.severity
    , fa.triggered_at
    , fa.resolved_at
    , ROUND(EXTRACT(EPOCH FROM (fa.resolved_at - fa.triggered_at)) / 60.0, 1) AS resolution_minutes
FROM gold.ft_alert fa
JOIN gold.dm_property dp  ON dp.property_key  = fa.property_key
JOIN gold.dm_person   dpe ON dpe.person_key   = fa.person_key
JOIN gold.dm_date     dd  ON dd.date_key      = fa.date_key;

CREATE OR REPLACE VIEW dw.vw_ft_user_goal AS
WITH consumption_per_person AS (
    SELECT
          up.user_id
        , AVG(cd.total_liters) AS avg_liters_last_30d
    FROM tb_user_property up
    JOIN gold.dm_property          gp ON gp.property_id   = up.property_id
    JOIN gold.ft_consumption_daily cd ON cd.property_key  = gp.property_key
    JOIN gold.dm_date              dd ON dd.date_key      = cd.date_key
    WHERE dd.full_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY up.user_id
)
SELECT
      dpe.user_id
    , dpe.name
    , pr.daily_liters_target
    , COALESCE(c.avg_liters_last_30d, 0) AS avg_liters_last_30d
    , ROUND(COALESCE(c.avg_liters_last_30d, 0) / NULLIF(pr.daily_liters_target, 0) * 100, 1) AS pct_of_target
FROM gold.dm_user_preference pr
JOIN gold.dm_person dpe ON dpe.person_key = pr.person_key
LEFT JOIN consumption_per_person c ON c.user_id = dpe.user_id;

-- Regras de negocio dos indicadores (documentadas aqui para o front nao recalcular):
--   goal_pct          = consumo do mes / meta mensal da unidade (tb_property_goal) * 100
--   goal_status       = 'OK' ate 85%, 'ATENCAO' ate 100%, 'CRITICO' acima de 100%; sem meta = 'SEM_META'
--   estimated_savings = (mes anterior - mes atual) em litros, so quando positivo, ao custo medio do m3 do mes
--   projected_liters  = consumo atual + (consumo atual - mes anterior), nunca negativo (projecao linear simples)
CREATE OR REPLACE VIEW dw.vw_ft_property_monthly AS
WITH staging_monthly AS (
    SELECT
          dp.property_key
        , dp.property_id
        , dp.name              AS property_name
        , dp.organization_id
        , dp.city
        , dp.state
        , dp.region_name
        , dp.latitude
        , dp.longitude
        , dp.built_area_m2
        , dp.monthly_target_liters
        , DATE_TRUNC('month', dd.full_date)::DATE AS reference_month
        , SUM(f.total_liters)  AS total_liters
        , SUM(f.cost_value)    AS total_cost
        , COUNT(DISTINCT f.date_key) AS days_with_data
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    JOIN gold.dm_date     dd ON dd.date_key     = f.date_key
    GROUP BY dp.property_key, dp.property_id, dp.name, dp.organization_id, dp.city, dp.state
           , dp.region_name, dp.latitude, dp.longitude, dp.built_area_m2, dp.monthly_target_liters
           , DATE_TRUNC('month', dd.full_date)
),
with_previous AS (
    SELECT
          m.*
        , LAG(m.total_liters) OVER (PARTITION BY m.property_id ORDER BY m.reference_month) AS previous_month_liters
    FROM staging_monthly m
),
with_goal AS (
    SELECT
          w.*
        , ROUND(w.total_liters / NULLIF(w.monthly_target_liters, 0) * 100, 1)       AS goal_pct
        , w.total_cost / NULLIF(w.total_liters, 0) * 1000                           AS avg_cost_per_m3
    FROM with_previous w
)
SELECT
      property_id
    , property_name
    , organization_id
    , city
    , state
    , region_name
    , latitude
    , longitude
    , built_area_m2
    , reference_month
    , days_with_data
    , (days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))) AS is_complete_month
    , total_liters
    , total_cost
    , ROUND(total_liters / NULLIF(built_area_m2, 0), 2)                              AS liters_per_m2
    , previous_month_liters
    , CASE WHEN days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))
           THEN ROUND((total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100, 1)
      END                                                                            AS variation_pct
    , monthly_target_liters
    , goal_pct
    , ROUND(monthly_target_liters / EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day')), 0) AS daily_limit_liters
    , GREATEST(monthly_target_liters - total_liters, 0)                                                              AS remaining_liters
    , CASE
          WHEN goal_pct IS NULL THEN 'SEM_META'
          WHEN goal_pct <= 85   THEN 'OK'
          WHEN goal_pct <= 100  THEN 'ATENCAO'
          ELSE 'CRITICO'
      END                                                                            AS goal_status
    -- Economia so e apurada em mes completo (mes parcial nao e comparavel com o anterior).
    , CASE WHEN days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))
           THEN GREATEST(COALESCE(previous_month_liters, 0) - total_liters, 0) * COALESCE(avg_cost_per_m3, 0) / 1000
           ELSE 0
      END                                                                            AS estimated_savings_value
    , CASE WHEN days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))
           THEN GREATEST(COALESCE(previous_month_liters, 0) - total_liters, 0)
           ELSE 0
      END                                                                            AS saved_liters
FROM with_goal;

CREATE OR REPLACE VIEW dw.vw_ft_organization_monthly_kpi AS
WITH agg_org AS (
    SELECT
          pm.organization_id
        , pm.reference_month
        , SUM(pm.total_liters)                                                     AS total_liters
        , SUM(pm.total_cost)                                                       AS total_cost
        , SUM(pm.previous_month_liters)                                            AS previous_month_liters
        , COUNT(*)                                                                 AS units_total
        , COUNT(*) FILTER (WHERE pm.goal_status = 'OK')                            AS units_on_target
        , COUNT(*) FILTER (WHERE pm.goal_status = 'ATENCAO')                       AS units_attention
        , COUNT(*) FILTER (WHERE pm.goal_status = 'CRITICO')                       AS units_critical
        , ROUND(AVG(pm.goal_pct), 1)                                               AS avg_goal_pct
        , SUM(pm.estimated_savings_value)                                          AS estimated_savings_value
        , SUM(pm.saved_liters)                                                     AS saved_liters
        , MIN(pm.days_with_data)                                                   AS min_days_with_data
        , BOOL_AND(pm.is_complete_month)                                           AS is_complete_month
    FROM dw.vw_ft_property_monthly pm
    WHERE pm.organization_id IS NOT NULL
    GROUP BY pm.organization_id, pm.reference_month
)
SELECT
      organization_id
    , reference_month
    , total_liters
    , total_cost
    , previous_month_liters
    , CASE WHEN is_complete_month
           THEN ROUND((total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100, 1)
      END                                                                          AS variation_pct
    , GREATEST(total_liters + (total_liters - COALESCE(previous_month_liters, total_liters)), 0) AS projected_liters
    , ROUND(
          GREATEST(total_liters + (total_liters - COALESCE(previous_month_liters, total_liters)), 0)
          * (total_cost / NULLIF(total_liters, 0))
        , 2
      )                                                                            AS projected_cost
    , units_total
    , units_on_target
    , units_attention
    , units_critical
    , avg_goal_pct
    , estimated_savings_value
    , saved_liters
    , min_days_with_data
    , is_complete_month
FROM agg_org;

CREATE OR REPLACE VIEW dw.vw_ft_monitoring_hourly AS
SELECT
      dp.organization_id
    , dp.property_id
    , dp.name                                   AS property_name
    , r.window_minutes
    , DATE_TRUNC('hour', r.read_at)             AS reading_hour
    , SUM(r.volume_liters)                      AS total_liters
    , ROUND(AVG(r.flow_lmin), 3)                AS avg_flow_lmin
    , COUNT(*)                                  AS readings_count
FROM gold.ft_consumption_reading r
JOIN gold.dm_property dp ON dp.property_key = r.property_key
GROUP BY dp.organization_id, dp.property_id, dp.name, r.window_minutes, DATE_TRUNC('hour', r.read_at);

CREATE OR REPLACE VIEW dw.vw_ft_device_status AS
SELECT
      dp.organization_id
    , dp.property_id
    , dp.name                                   AS property_name
    , dp.region_name
    , ds.device_id
    , ds.is_active
    , ds.connectivity_status
    , (LOWER(ds.connectivity_status) IN ('online', 'connected')) AS is_online
    , ds.battery_level
    , (ds.battery_level IS NOT NULL AND ds.battery_level <= 20)  AS is_low_battery
    , ds.wifi_signal_rssi
    , ds.firmware_version
    , ds.last_ping_at
    , ds.unavailability_reason
FROM gold.dm_device_status ds
JOIN gold.dm_property dp ON dp.property_key = ds.property_key;

CREATE OR REPLACE VIEW dw.vw_ft_organization_device_summary AS
WITH agg_devices AS (
    SELECT
          organization_id
        , COUNT(*) FILTER (WHERE is_active)                            AS devices_paired
        , COUNT(*) FILTER (WHERE is_active AND is_online)              AS devices_online
        , COUNT(*) FILTER (WHERE is_active AND is_low_battery)         AS devices_low_battery
        , COUNT(DISTINCT property_id) FILTER (WHERE is_active)         AS properties_with_device
    FROM dw.vw_ft_device_status
    GROUP BY organization_id
),
agg_properties AS (
    SELECT organization_id, COUNT(*) AS properties_total
    FROM gold.dm_property
    WHERE organization_id IS NOT NULL
    GROUP BY organization_id
)
SELECT
      p.organization_id
    , p.properties_total
    , COALESCE(d.devices_paired, 0)          AS devices_paired
    , COALESCE(d.devices_online, 0)          AS devices_online
    , COALESCE(d.devices_low_battery, 0)     AS devices_low_battery
    , p.properties_total - COALESCE(d.properties_with_device, 0) AS properties_without_device
FROM agg_properties p
LEFT JOIN agg_devices d ON d.organization_id = p.organization_id;

CREATE OR REPLACE VIEW dw.vw_ft_leak AS
WITH staging_leak AS (
    SELECT
          fa.alert_key
        , dp.property_key
        , dp.property_id
        , dp.name                AS property_name
        , dp.organization_id
        , fa.device_id
        , fa.severity
        , fa.triggered_at
        , fa.resolved_at
    FROM gold.ft_alert fa
    JOIN gold.dm_property dp ON dp.property_key = fa.property_key
    WHERE fa.alert_type = 'vazamento_continuo'
),
agg_loss AS (
    SELECT
          l.alert_key
        , COALESCE(SUM(r.volume_liters), 0) AS estimated_loss_liters
    FROM staging_leak l
    LEFT JOIN gold.ft_consumption_reading r
           ON r.device_id = l.device_id
          AND r.read_at  >= l.triggered_at
          AND r.read_at  <= COALESCE(l.resolved_at, CURRENT_TIMESTAMP)
    GROUP BY l.alert_key
),
with_cost AS (
    SELECT
          l.*
        , a.estimated_loss_liters
        , COALESCE((
              SELECT SUM(f.cost_value) / NULLIF(SUM(f.total_liters), 0) * 1000
                FROM gold.ft_consumption_daily f
               WHERE f.property_key = l.property_key
          ), 0)                      AS avg_cost_per_m3
    FROM staging_leak l
    JOIN agg_loss a ON a.alert_key = l.alert_key
)
SELECT
      alert_key
    , organization_id
    , property_id
    , property_name
    , device_id
    , severity
    , triggered_at
    , resolved_at
    , CASE WHEN resolved_at IS NULL THEN 'ATIVO' ELSE 'RESOLVIDO' END AS leak_status
    , ROUND(EXTRACT(EPOCH FROM (COALESCE(resolved_at, CURRENT_TIMESTAMP) - triggered_at)) / 60.0, 1) AS duration_minutes
    , estimated_loss_liters
    , ROUND(estimated_loss_liters / 1000.0 * avg_cost_per_m3, 2)       AS estimated_loss_cost
FROM with_cost;

-- Equivalencias do painel ESG: 1 caminhao-pipa = 10.000 L; familia de 4 pessoas = 18.000 L/mes (150 L/pessoa/dia x 30 dias).
CREATE OR REPLACE VIEW dw.vw_ft_organization_esg AS
SELECT
      k.organization_id
    , k.reference_month
    , k.saved_liters                                  AS saved_liters_month
    , k.saved_liters * 12                             AS saved_liters_year_projection
    , ROUND(k.saved_liters * 12 / 10000.0, 1)         AS tank_trucks_equivalent
    , ROUND(k.saved_liters * 12 / 18000.0, 1)         AS family_months_equivalent
    , k.units_total
    , k.units_on_target
    , k.avg_goal_pct
    , k.estimated_savings_value
    , k.is_complete_month
FROM dw.vw_ft_organization_monthly_kpi k;

-- Impacto de cada cenário de investimento sobre o consumo da organização.
-- Linha de base: média mensal dos meses fechados * 12. Cenário sem organização vale para todas.
--   saved_liters_year = linha de base anual * redução do cenário
--   tank_trucks       = litros economizados / 10.000 L por caminhão-pipa
--   family_months     = litros economizados / 18.000 L (4 pessoas x 150 L/dia x 30 dias)
CREATE OR REPLACE VIEW dw.vw_ft_investment_impact AS
WITH agg_baseline AS (
    SELECT
          organization_id
        , AVG(total_liters) * 12 AS baseline_annual_liters
    FROM dw.vw_ft_organization_monthly_kpi
    WHERE is_complete_month
    GROUP BY organization_id
),
staging_scenario AS (
    SELECT
          s.scenario_id
        , b.organization_id
        , s.name
        , s.investment_value
        , s.reduction_pct
        , s.annual_savings_value
        , s.payback_months
        , b.baseline_annual_liters
    FROM gold.ft_investment_scenario s
    JOIN agg_baseline b
      ON s.organization_id IS NULL OR s.organization_id = b.organization_id
)
SELECT
      scenario_id
    , organization_id
    , name
    , investment_value
    , reduction_pct
    , annual_savings_value
    , payback_months
    , ROUND(baseline_annual_liters, 0)                                        AS baseline_annual_liters
    , ROUND(baseline_annual_liters * reduction_pct / 100, 0)                  AS saved_liters_year
    , ROUND(baseline_annual_liters * reduction_pct / 100 / 10000.0, 1)        AS tank_trucks_equivalent
    , ROUND(baseline_annual_liters * reduction_pct / 100 / 18000.0, 1)        AS family_months_equivalent
FROM staging_scenario;

GRANT USAGE ON SCHEMA stage, silver, gold, dw TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO sys_data_engineer;

GRANT USAGE ON SCHEMA gold, dw TO sys_bi_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA gold, dw TO sys_bi_analyst;

ALTER DEFAULT PRIVILEGES IN SCHEMA stage, silver, gold
    GRANT ALL ON TABLES TO sys_data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA stage, silver, gold
    GRANT ALL ON SEQUENCES TO sys_data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA dw
    GRANT SELECT ON TABLES TO sys_data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA gold, dw
    GRANT SELECT ON TABLES TO sys_bi_analyst;

