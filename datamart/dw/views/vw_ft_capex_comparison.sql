CREATE OR REPLACE VIEW dw.vw_ft_capex_comparison AS
WITH staging_scenario AS (
    SELECT
          scenario_id
        , name
        , investment_value
        , reduction_pct
        , annual_savings_value
        , payback_months
    FROM gold.ft_investment_scenario
)
SELECT
      scenario_id
    , name
    , investment_value
    , reduction_pct
    , annual_savings_value
    , payback_months
    , RANK() OVER (ORDER BY payback_months ASC NULLS LAST) AS rank_by_payback
FROM staging_scenario;
