CREATE OR REPLACE FUNCTION fn_user_location(
    p_user_id INTEGER
)
RETURNS TABLE (
    city  VARCHAR,
    state VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          a.city
        , a.state
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
