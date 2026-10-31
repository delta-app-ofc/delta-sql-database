DROP FUNCTION IF EXISTS fn_organization_last_billed_period(INTEGER[], DATE);

CREATE OR REPLACE FUNCTION fn_organization_last_billed_period(
    p_user_id      INTEGER,
    p_property_ids INTEGER[],
    p_today        DATE
)
RETURNS TABLE (
    reference_month DATE,
    total_liters    NUMERIC,
    total_cost      NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
    v_last_closed_month DATE := DATE_TRUNC('month', p_today) - INTERVAL '1 month';
BEGIN

    RETURN QUERY
    SELECT
          v_last_closed_month
        , SUM(v.total_liters)
        , SUM(v.cost_value)
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
       AND DATE_TRUNC('month', v.full_date) = v_last_closed_month
    HAVING SUM(v.total_liters) IS NOT NULL;

    IF FOUND THEN
        RETURN;
    END IF;


    RETURN QUERY
    SELECT
          DATE_TRUNC('month', MAX(v.full_date))::DATE
        , SUM(v.total_liters)
        , SUM(v.cost_value)
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
    HAVING SUM(v.total_liters) IS NOT NULL;

END;
$$;
