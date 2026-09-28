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
            , ROUND(sd.total_liters / 1000.0 * fn_get_current_region_rate(sd.region_id, sd.classification_id, sd.consumption_day), 2) AS cost_value
        FROM staging_daily sd
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
