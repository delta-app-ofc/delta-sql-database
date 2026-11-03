CREATE OR REPLACE VIEW dw.vw_ft_organization_monthly_kpi AS
WITH agg_org AS (
    SELECT
          pm.organization_id
        , pm.reference_month
        , SUM(pm.total_liters)                                                     AS total_liters
        , SUM(pm.total_cost)                                                       AS total_cost
        , SUM(pm.previous_month_liters)                                            AS previous_month_liters
        , COUNT(*)                                                                 AS units_total
        , COUNT(*) FILTER (WHERE pm.goal_status = 'OK')                            AS units_on_target
        , COUNT(*) FILTER (WHERE pm.goal_status = 'ATENCAO')                       AS units_attention
        , COUNT(*) FILTER (WHERE pm.goal_status = 'CRITICO')                       AS units_critical
        , ROUND(AVG(pm.goal_pct), 1)                                               AS avg_goal_pct
        , SUM(pm.estimated_savings_value)                                          AS estimated_savings_value
        , SUM(pm.saved_liters)                                                     AS saved_liters
        , MIN(pm.days_with_data)                                                   AS min_days_with_data
        , BOOL_AND(pm.is_complete_month)                                           AS is_complete_month
    FROM dw.vw_ft_property_monthly pm
    WHERE pm.organization_id IS NOT NULL
    GROUP BY pm.organization_id, pm.reference_month
)
SELECT
      organization_id
    , reference_month
    , total_liters
    , total_cost
    , previous_month_liters
    , CASE WHEN is_complete_month
           THEN ROUND((total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100, 1)
      END                                                                          AS variation_pct
    , GREATEST(total_liters + (total_liters - COALESCE(previous_month_liters, total_liters)), 0) AS projected_liters
    , ROUND(
          GREATEST(total_liters + (total_liters - COALESCE(previous_month_liters, total_liters)), 0)
          * (total_cost / NULLIF(total_liters, 0))
        , 2
      )                                                                            AS projected_cost
    , units_total
    , units_on_target
    , units_attention
    , units_critical
    , avg_goal_pct
    , estimated_savings_value
    , saved_liters
    , min_days_with_data
    , is_complete_month
FROM agg_org;

