CREATE OR REPLACE FUNCTION fn_user_organization_properties(
    p_user_id INTEGER
)
RETURNS TABLE (
    property_id INTEGER,
    name        VARCHAR,
    city        VARCHAR,
    state       VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Propriedades de todas as organizações do usuário (M:N, sem papel/hierarquia)
    RETURN QUERY
    SELECT
          p.id
        , p.name
        , a.city
        , a.state
      FROM tb_user_organization uo
      JOIN tb_property p
        ON p.organization_id = uo.organization_id
      JOIN tb_address a
        ON a.id = p.address_id
     WHERE uo.user_id = p_user_id;

END;
$$;
