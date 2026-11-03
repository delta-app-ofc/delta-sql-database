-- ============================================================
-- MIGRACAO DOS INDICADORES (views dw, metas, status de dispositivos)
-- ============================================================
-- Para bancos que ja tem as camadas stage/silver/gold/dw criadas por uma
-- versao anterior do script-datamart.sql. Idempotente: pode rodar mais de
-- uma vez. Gerada a partir do script-datamart.sql; depois de rodar, execute
-- CALL silver.sp_load(); CALL gold.sp_load(); para preencher as novas colunas.
-- ============================================================

BEGIN;

-- OLTP: meta mensal por unidade
CREATE TABLE IF NOT EXISTS tb_property_goal (
      property_id                                 INTEGER       PRIMARY KEY
    , monthly_target_liters                       NUMERIC(12,2) NOT NULL
      CONSTRAINT chk_tb_property_goal_monthly_target_liters
        CHECK (monthly_target_liters > 0)
    , updated_at                                  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
    , CONSTRAINT fk_tb_property_goal_property     FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
-- stage / silver / gold: novas tabelas
CREATE TABLE IF NOT EXISTS stage.device_status (
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

CREATE TABLE IF NOT EXISTS silver.dm_device_status (
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

CREATE TABLE IF NOT EXISTS gold.ft_consumption_reading (
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

CREATE TABLE IF NOT EXISTS gold.dm_device_status (
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

-- silver / gold: novas colunas
ALTER TABLE silver.dm_property            ADD COLUMN IF NOT EXISTS region_name           VARCHAR(60);
ALTER TABLE silver.dm_property            ADD COLUMN IF NOT EXISTS latitude              NUMERIC(8,6);
ALTER TABLE silver.dm_property            ADD COLUMN IF NOT EXISTS longitude             NUMERIC(9,6);
ALTER TABLE silver.dm_property            ADD COLUMN IF NOT EXISTS monthly_target_liters NUMERIC(12,2);
ALTER TABLE silver.ft_consumption_reading ADD COLUMN IF NOT EXISTS window_minutes        SMALLINT NOT NULL DEFAULT 10;
ALTER TABLE gold.dm_property              ADD COLUMN IF NOT EXISTS organization_id       INTEGER;
ALTER TABLE gold.dm_property              ADD COLUMN IF NOT EXISTS region_name           VARCHAR(60);
ALTER TABLE gold.dm_property              ADD COLUMN IF NOT EXISTS latitude              NUMERIC(8,6);
ALTER TABLE gold.dm_property              ADD COLUMN IF NOT EXISTS longitude             NUMERIC(9,6);
ALTER TABLE gold.dm_property              ADD COLUMN IF NOT EXISTS monthly_target_liters NUMERIC(12,2);
ALTER TABLE gold.ft_investment_scenario   ADD COLUMN IF NOT EXISTS organization_id       INTEGER;

-- procedures
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

-- views: recriadas do zero porque CREATE OR REPLACE nao permite inserir colunas no meio; as dependentes sao recriadas logo abaixo
DROP VIEW IF EXISTS dw.vw_ft_property_monthly CASCADE;
DROP VIEW IF EXISTS dw.vw_ft_monitoring_hourly CASCADE;
DROP VIEW IF EXISTS dw.vw_ft_device_status CASCADE;
DROP VIEW IF EXISTS dw.vw_ft_leak CASCADE;

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

CREATE OR REPLACE VIEW dw.vw_ft_organization_esg AS
SELECT
      k.organization_id
    , k.reference_month
    , k.saved_liters                                  AS saved_liters_month
    , k.saved_liters * 12                             AS saved_liters_year_projection
    , ROUND(k.saved_liters * 12 / 10000.0, 1)         AS tank_trucks_equivalent
    , ROUND(k.saved_liters * 12 / 15000.0, 1)         AS family_months_equivalent
    , k.units_total
    , k.units_on_target
    , k.avg_goal_pct
    , k.estimated_savings_value
    , k.is_complete_month
FROM dw.vw_ft_organization_monthly_kpi k;

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
    , ROUND(baseline_annual_liters * reduction_pct / 100 / 15000.0, 1)        AS family_months_equivalent
FROM staging_scenario;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO sys_data_engineer;
GRANT SELECT ON ALL TABLES IN SCHEMA gold, dw TO sys_bi_analyst;

COMMIT;