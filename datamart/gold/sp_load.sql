CREATE OR REPLACE PROCEDURE gold.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.dm_date (date_key, full_date, day_of_week, day_name, week_of_year, month_number, quarter_number, year_number, is_weekend)
    SELECT
          TO_CHAR(d, 'YYYYMMDD')::INTEGER
        , d
        , EXTRACT(DOW FROM d)
        , TRIM(TO_CHAR(d, 'Day'))
        , EXTRACT(WEEK FROM d)
        , EXTRACT(MONTH FROM d)
        , EXTRACT(QUARTER FROM d)
        , EXTRACT(YEAR FROM d)
        , EXTRACT(DOW FROM d) IN (0, 6)
    FROM generate_series('2024-01-01'::DATE, '2028-12-31'::DATE, INTERVAL '1 day') AS d
    ON CONFLICT (date_key) DO NOTHING;

    INSERT INTO gold.dm_property (property_id, name, property_type, classification_group, city, state, built_area_m2, organization_name, has_operational_profile)
    SELECT property_id, name, property_type, classification_group, city, state, built_area_m2, organization_name, has_operational_profile
    FROM silver.property
    ON CONFLICT (property_id) DO UPDATE
        SET name                     = EXCLUDED.name
          , property_type            = EXCLUDED.property_type
          , classification_group     = EXCLUDED.classification_group
          , city                     = EXCLUDED.city
          , state                    = EXCLUDED.state
          , built_area_m2            = EXCLUDED.built_area_m2
          , organization_name        = EXCLUDED.organization_name
          , has_operational_profile  = EXCLUDED.has_operational_profile;

    INSERT INTO gold.dm_person (user_id, name, profile_type)
    SELECT user_id, name, profile_type
    FROM silver.person
    ON CONFLICT (user_id) DO UPDATE
        SET name         = EXCLUDED.name
          , profile_type = EXCLUDED.profile_type;

    WITH staging_daily AS (
        SELECT
              cd.property_id
            , cd.consumption_day
            , cd.total_liters
            , cd.avg_flow_lmin
            , sp.region_id
            , sp.classification_id
        FROM silver.consumption_daily cd
        JOIN silver.property sp ON sp.property_id = cd.property_id
    ),
    with_cost AS (
        SELECT
              sd.*
            , ROUND(sd.total_liters / 1000.0 * fn_get_current_region_rate(sd.region_id, sd.classification_id, sd.consumption_day), 2) AS cost_value
        FROM staging_daily sd
    )
    INSERT INTO gold.ft_consumption_daily (property_key, date_key, total_liters, avg_flow_lmin, cost_value)
    SELECT
          dp.property_key
        , TO_CHAR(wc.consumption_day, 'YYYYMMDD')::INTEGER
        , wc.total_liters
        , wc.avg_flow_lmin
        , wc.cost_value
    FROM with_cost wc
    JOIN gold.dm_property dp ON dp.property_id = wc.property_id
    ON CONFLICT (property_key, date_key) DO UPDATE
        SET total_liters  = EXCLUDED.total_liters
          , avg_flow_lmin = EXCLUDED.avg_flow_lmin
          , cost_value    = EXCLUDED.cost_value;

    INSERT INTO gold.ft_water_bill_monthly (person_key, date_key, total_value, m3_value)
    SELECT
          dp.person_key
        , TO_CHAR(wb.bill_month, 'YYYYMMDD')::INTEGER
        , wb.total_value
        , wb.m3_value
    FROM silver.water_bill wb
    JOIN gold.dm_person dp ON dp.user_id = wb.user_id
    ON CONFLICT (person_key, date_key) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value    = EXCLUDED.m3_value;

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
