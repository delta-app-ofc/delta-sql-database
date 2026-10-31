DROP FUNCTION IF EXISTS fn_organization_consumption_history(INTEGER[], INTEGER, DATE);

CREATE OR REPLACE FUNCTION fn_organization_consumption_history(
    p_user_id      INTEGER,
    p_property_ids INTEGER[],
    p_days         INTEGER,
    p_today        DATE
)
RETURNS TABLE (
    full_date    DATE,
    total_liters NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
BEGIN

    RETURN QUERY
    SELECT
          v.full_date
        , SUM(v.total_liters) AS total_liters
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
       AND v.full_date BETWEEN (p_today - (p_days - 1)) AND p_today
     GROUP BY v.full_date
     ORDER BY v.full_date;

END;
$$;
