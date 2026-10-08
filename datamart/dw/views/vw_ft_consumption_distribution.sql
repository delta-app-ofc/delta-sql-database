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
