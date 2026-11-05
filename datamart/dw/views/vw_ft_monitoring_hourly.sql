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

