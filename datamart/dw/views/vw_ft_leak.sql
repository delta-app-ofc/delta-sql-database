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

