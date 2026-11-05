-- Regras de negocio dos indicadores (documentadas aqui para o front nao recalcular):
--   goal_pct          = consumo do mes / meta mensal da unidade (tb_property_goal) * 100
--   goal_status       = 'OK' ate 85%, 'ATENCAO' ate 100%, 'CRITICO' acima de 100%; sem meta = 'SEM_META'
--   estimated_savings = (mes anterior - mes atual) em litros, so quando positivo, ao custo medio do m3 do mes
--   projected_liters  = consumo atual + (consumo atual - mes anterior), nunca negativo (projecao linear simples)
CREATE OR REPLACE VIEW dw.vw_ft_property_monthly AS
WITH staging_monthly AS (
    SELECT
          dp.property_key
        , dp.property_id
        , dp.name              AS property_name
        , dp.organization_id
        , dp.city
        , dp.state
        , dp.region_name
        , dp.latitude
        , dp.longitude
        , dp.built_area_m2
        , dp.monthly_target_liters
        , DATE_TRUNC('month', dd.full_date)::DATE AS reference_month
        , SUM(f.total_liters)  AS total_liters
        , SUM(f.cost_value)    AS total_cost
        , COUNT(DISTINCT f.date_key) AS days_with_data
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    JOIN gold.dm_date     dd ON dd.date_key     = f.date_key
    GROUP BY dp.property_key, dp.property_id, dp.name, dp.organization_id, dp.city, dp.state
           , dp.region_name, dp.latitude, dp.longitude, dp.built_area_m2, dp.monthly_target_liters
           , DATE_TRUNC('month', dd.full_date)
),
with_previous AS (
    SELECT
          m.*
        , LAG(m.total_liters) OVER (PARTITION BY m.property_id ORDER BY m.reference_month) AS previous_month_liters
    FROM staging_monthly m
),
with_goal AS (
    SELECT
          w.*
        , ROUND(w.total_liters / NULLIF(w.monthly_target_liters, 0) * 100, 1)       AS goal_pct
        , w.total_cost / NULLIF(w.total_liters, 0) * 1000                           AS avg_cost_per_m3
    FROM with_previous w
)
SELECT
      property_id
    , property_name
    , organization_id
    , city
    , state
    , region_name
    , latitude
    , longitude
    , built_area_m2
    , reference_month
    , days_with_data
    , (days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))) AS is_complete_month
    , total_liters
    , total_cost
    , ROUND(total_liters / NULLIF(built_area_m2, 0), 2)                              AS liters_per_m2
    , previous_month_liters
    , CASE WHEN days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))
           THEN ROUND((total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100, 1)
      END                                                                            AS variation_pct
    , monthly_target_liters
    , goal_pct
    , ROUND(monthly_target_liters / EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day')), 0) AS daily_limit_liters
    , GREATEST(monthly_target_liters - total_liters, 0)                                                              AS remaining_liters
    , CASE
          WHEN goal_pct IS NULL THEN 'SEM_META'
          WHEN goal_pct <= 85   THEN 'OK'
          WHEN goal_pct <= 100  THEN 'ATENCAO'
          ELSE 'CRITICO'
      END                                                                            AS goal_status
    -- Economia so e apurada em mes completo (mes parcial nao e comparavel com o anterior).
    , CASE WHEN days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))
           THEN GREATEST(COALESCE(previous_month_liters, 0) - total_liters, 0) * COALESCE(avg_cost_per_m3, 0) / 1000
           ELSE 0
      END                                                                            AS estimated_savings_value
    , CASE WHEN days_with_data >= EXTRACT(DAY FROM (reference_month + INTERVAL '1 month' - INTERVAL '1 day'))
           THEN GREATEST(COALESCE(previous_month_liters, 0) - total_liters, 0)
           ELSE 0
      END                                                                            AS saved_liters
FROM with_goal;

