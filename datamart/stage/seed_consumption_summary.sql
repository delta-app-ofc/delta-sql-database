BEGIN;

INSERT INTO stage.consumption_summary (device_id, window_started_at, window_finished_at, consumption_liters, lpm_average, anomaly_detected)
SELECT
      p.device_id
    , p.window_start
    , p.window_start + INTERVAL '15 minutes'
    , ROUND((p.base_flow_lmin * (0.6 + random() * 0.8) * 15)::NUMERIC, 3)
    , ROUND((p.base_flow_lmin * (0.6 + random() * 0.8))::NUMERIC, 3)
    , FALSE
FROM (
    SELECT
          pr.device_id
        , pr.base_flow_lmin
        , window_start
    FROM (VALUES
          ('ESP32151', 2.0)
        , ('ESP32152', 3.5)
        , ('ESP32153', 5.0)
        , ('ESP32154', 8.0)
        , ('ESP32155', 12.0)
    ) AS pr (device_id, base_flow_lmin)
    CROSS JOIN generate_series(
          CURRENT_DATE - INTERVAL '60 days'
        , CURRENT_DATE - INTERVAL '15 minutes'
        , INTERVAL '15 minutes'
    ) AS window_start
) AS p;

COMMIT;
