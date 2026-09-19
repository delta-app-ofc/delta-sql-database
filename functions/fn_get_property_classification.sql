CREATE OR REPLACE FUNCTION fn_get_property_classification(
    p_property_id INTEGER
)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
DECLARE
    v_classification VARCHAR(50);
BEGIN

    SELECT pc.name
      INTO v_classification
      FROM tb_property p
      JOIN tb_property_classification pc
        ON pc.id = p.classification_id
     WHERE p.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Imóvel com id % não encontrado.',
            p_property_id;
    END IF;

    RETURN v_classification;

END;
$$;
