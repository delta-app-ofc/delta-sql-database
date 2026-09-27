-- Grao: instalacao x dia (industrial). Window functions: SUM() OVER pra
-- total acumulado no periodo e AVG() OVER pra media movel de 7 dias -
-- espelha o card de consumo acumulado do prototipo.
CREATE OR REPLACE VIEW dw.vw_consumption_daily AS
WITH staging_consumption AS (
    SELECT
          f.property_key
        , dp.property_id
        , dp.name           AS property_name
        , dd.full_date
        , f.total_liters
        , f.cost_value
    FROM gold.fact_consumption_daily f
    JOIN gold.dim_property dp ON dp.property_key = f.property_key
    JOIN gold.dim_date dd     ON dd.date_key = f.date_key
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
