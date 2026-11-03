-- Impacto de cada cenário de investimento sobre o consumo da organização.
-- Linha de base: média mensal dos meses fechados * 12. Cenário sem organização vale para todas.
--   saved_liters_year = linha de base anual * redução do cenário
--   tank_trucks       = litros economizados / 10.000 L por caminhão-pipa
--   family_months     = litros economizados / 15.000 L (consumo mensal de uma família de 4 pessoas)
CREATE OR REPLACE VIEW dw.vw_ft_investment_impact AS
WITH agg_baseline AS (
    SELECT
          organization_id
        , AVG(total_liters) * 12 AS baseline_annual_liters
    FROM dw.vw_ft_organization_monthly_kpi
    WHERE is_complete_month
    GROUP BY organization_id
),
staging_scenario AS (
    SELECT
          s.scenario_id
        , b.organization_id
        , s.name
        , s.investment_value
        , s.reduction_pct
        , s.annual_savings_value
        , s.payback_months
        , b.baseline_annual_liters
    FROM gold.ft_investment_scenario s
    JOIN agg_baseline b
      ON s.organization_id IS NULL OR s.organization_id = b.organization_id
)
SELECT
      scenario_id
    , organization_id
    , name
    , investment_value
    , reduction_pct
    , annual_savings_value
    , payback_months
    , ROUND(baseline_annual_liters, 0)                                        AS baseline_annual_liters
    , ROUND(baseline_annual_liters * reduction_pct / 100, 0)                  AS saved_liters_year
    , ROUND(baseline_annual_liters * reduction_pct / 100 / 10000.0, 1)        AS tank_trucks_equivalent
    , ROUND(baseline_annual_liters * reduction_pct / 100 / 15000.0, 1)        AS family_months_equivalent
FROM staging_scenario;
