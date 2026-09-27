CREATE OR REPLACE PROCEDURE gold.sp_load_ft_investment_scenario()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_investment_scenario (scenario_id, name, investment_value, reduction_pct, annual_savings_value, payback_months)
    SELECT id, name, investment_value, reduction_pct, annual_savings_value, payback_months
    FROM tb_investment_scenario
    ON CONFLICT (scenario_id) DO UPDATE
        SET name                 = EXCLUDED.name
          , investment_value     = EXCLUDED.investment_value
          , reduction_pct        = EXCLUDED.reduction_pct
          , annual_savings_value = EXCLUDED.annual_savings_value
          , payback_months       = EXCLUDED.payback_months;

END;
$$;
