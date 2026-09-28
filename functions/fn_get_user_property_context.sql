CREATE OR REPLACE FUNCTION fn_get_user_property_context(
    p_user_id INTEGER
)
RETURNS TABLE (
    region_id         INTEGER,
    classification_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Primeira propriedade vinculada ao usuário (mesmo critério das duas
    -- consultas Python que esta function substitui: ORDER BY up.id LIMIT 1)
    RETURN QUERY
    SELECT
          a.region_id
        , p.classification_id
      FROM tb_user_property up
      JOIN tb_property p
        ON p.id = up.property_id
      JOIN tb_address a
        ON a.id = p.address_id
     WHERE up.user_id = p_user_id
     ORDER BY up.id
     LIMIT 1;

END;
$$;
