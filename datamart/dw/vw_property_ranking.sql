CREATE OR REPLACE VIEW dw.vw_property_ranking AS
WITH agg_consumption AS (
    SELECT
          dp.property_id
        , dp.name             AS property_name
        , dp.built_area_m2
        , SUM(f.total_liters) AS total_liters
        , SUM(f.cost_value)   AS total_cost
    FROM gold.fact_consumption_daily f
    JOIN gold.dim_property dp ON dp.property_key = f.property_key
    WHERE dp.built_area_m2 IS NOT NULL
    GROUP BY dp.property_id, dp.name, dp.built_area_m2
),
final_ranking AS (
    SELECT
          property_id
        , property_name
        , total_liters
        , total_cost
        , ROUND(total_liters / built_area_m2, 2) AS liters_per_m2
    FROM agg_consumption
)
SELECT
      property_id
    , property_name
    , total_liters
    , total_cost
    , liters_per_m2
    , RANK()         OVER (ORDER BY liters_per_m2 ASC)  AS rank_efficiency
    , DENSE_RANK()   OVER (ORDER BY total_cost DESC)    AS rank_cost
    , NTILE(4)       OVER (ORDER BY liters_per_m2)      AS consumption_quartile
    , PERCENT_RANK() OVER (ORDER BY liters_per_m2)      AS consumption_percent_rank
FROM final_ranking;
