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
