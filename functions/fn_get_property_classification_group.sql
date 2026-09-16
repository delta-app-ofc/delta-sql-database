CREATE OR REPLACE FUNCTION fn_get_property_classification_group(
    p_property_id INTEGER
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_group_name VARCHAR(20);
BEGIN

    SELECT pc.group_name
      INTO v_group_name
      FROM tb_property p
      JOIN tb_property_classification pc
        ON pc.id = p.classification_id
     WHERE p.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Imóvel com id % não encontrado.',
            p_property_id;
    END IF;

    RETURN v_group_name;

END;
$$;
