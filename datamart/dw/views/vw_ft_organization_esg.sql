-- Equivalencias do painel ESG: 1 caminhao-pipa = 10.000 L; familia de 4 pessoas = 18.000 L/mes (150 L/pessoa/dia x 30 dias).
CREATE OR REPLACE VIEW dw.vw_ft_organization_esg AS
SELECT
      k.organization_id
    , k.reference_month
    , k.saved_liters                                  AS saved_liters_month
    , k.saved_liters * 12                             AS saved_liters_year_projection
    , ROUND(k.saved_liters * 12 / 10000.0, 1)         AS tank_trucks_equivalent
    , ROUND(k.saved_liters * 12 / 18000.0, 1)         AS family_months_equivalent
    , k.units_total
    , k.units_on_target
    , k.avg_goal_pct
    , k.estimated_savings_value
    , k.is_complete_month
FROM dw.vw_ft_organization_monthly_kpi k;

