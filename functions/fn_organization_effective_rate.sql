DROP FUNCTION IF EXISTS fn_organization_effective_rate(INTEGER[], DATE, INTEGER);

CREATE OR REPLACE FUNCTION fn_organization_effective_rate(
    p_user_id      INTEGER,
    p_property_ids  INTEGER[],
    p_today         DATE,
    p_window_days   INTEGER DEFAULT 30
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
    v_total_liters NUMERIC;
    v_total_cost   NUMERIC;
BEGIN

    SELECT
          SUM(v.total_liters)
        , SUM(v.cost_value)
      INTO v_total_liters, v_total_cost
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
       AND v.full_date BETWEEN (p_today - (p_window_days - 1)) AND p_today;

    IF v_total_liters IS NULL OR v_total_liters = 0 THEN
        RETURN NULL;
    END IF;

    RETURN v_total_cost / (v_total_liters / 1000);

END;
$$;
