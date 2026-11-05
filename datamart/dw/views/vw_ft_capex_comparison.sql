CREATE OR REPLACE VIEW dw.vw_ft_capex_comparison AS
WITH staging_scenario AS (
    SELECT
          fact.scenario_id
        , scenario.name
        , fact.investment_value
        , fact.reduction_pct
        , fact.annual_savings_value
        , fact.payback_months
    FROM gold.ft_investment_scenario AS fact
    INNER JOIN tb_investment_scenario AS scenario
        ON scenario.id = fact.scenario_id
    WHERE UPPER(scenario.name) NOT LIKE 'SIMULACAO DASH%'
      AND UPPER(scenario.name) NOT LIKE 'SIMULAÇÃO DASH%'
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
