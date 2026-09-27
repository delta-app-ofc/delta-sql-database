BEGIN;

INSERT INTO stage.consumption_reading_raw (property_id, read_at, volume_liters, flow_lmin)
SELECT
      p.property_id
    , p.read_at
    , ROUND((p.base_flow_lmin * (0.6 + random() * 0.8) * 15)::NUMERIC, 3) AS volume_liters
    , ROUND((p.base_flow_lmin * (0.6 + random() * 0.8))::NUMERIC, 3)      AS flow_lmin
FROM (
    SELECT
          pr.property_id
        , pr.base_flow_lmin
        , read_at
    FROM (VALUES
          (151, 2.0)
        , (152, 3.5)
        , (153, 5.0)
        , (154, 8.0)
        , (155, 12.0)
    ) AS pr (property_id, base_flow_lmin)
    CROSS JOIN generate_series(
          CURRENT_DATE - INTERVAL '60 days'
        , CURRENT_DATE - INTERVAL '15 minutes'
        , INTERVAL '15 minutes'
    ) AS read_at
) AS p;

COMMIT;
