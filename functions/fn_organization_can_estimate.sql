DROP FUNCTION IF EXISTS fn_organization_can_estimate(INTEGER[]);

CREATE OR REPLACE FUNCTION fn_organization_can_estimate(
    p_user_id      INTEGER,
    p_property_ids INTEGER[]
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
BEGIN

    RETURN EXISTS
    (
        SELECT 1
          FROM gold.ft_consumption_daily f
          JOIN gold.dm_property dp
            ON dp.property_key = f.property_key
         WHERE dp.property_id = ANY(v_property_ids)
    );

END;
$$;
