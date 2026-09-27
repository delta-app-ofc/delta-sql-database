-- Grao: instalacao x mes (industrial). Window function: LAG() pra variacao
-- % mes a mes - espelha o "varMes" hoje estatico no prototipo.
CREATE OR REPLACE VIEW dw.vw_monthly_variation AS
WITH staging_monthly AS (
    SELECT
          dp.property_id
        , dp.name AS property_name
        , DATE_TRUNC('month', dd.full_date)::DATE AS reference_month
        , SUM(f.total_liters) AS total_liters
    FROM gold.fact_consumption_daily f
    JOIN gold.dim_property dp ON dp.property_key = f.property_key
    JOIN gold.dim_date dd     ON dd.date_key = f.date_key
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
