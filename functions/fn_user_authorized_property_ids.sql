CREATE OR REPLACE FUNCTION fn_user_authorized_property_ids(
    p_user_id      INTEGER,
    p_property_ids INTEGER[]
)
RETURNS INTEGER[]
LANGUAGE plpgsql
AS $$
DECLARE
    v_authorized INTEGER[];
BEGIN

    SELECT COALESCE(ARRAY_AGG(p.id), ARRAY[]::INTEGER[])
      INTO v_authorized
      FROM tb_user_organization uo
      JOIN tb_property p
        ON p.organization_id = uo.organization_id
     WHERE uo.user_id = p_user_id
       AND p.id = ANY(p_property_ids);

    RETURN v_authorized;

END;
$$;
