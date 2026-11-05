CREATE OR REPLACE FUNCTION fn_user_can_estimate(
    p_user_id INTEGER,
    p_reference_date DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_id INTEGER;
    v_region_id INTEGER;
    v_classification_id INTEGER;
BEGIN

    -- Verifica se o usuário existe e está ativo
    IF NOT fn_user_is_active(p_user_id) THEN
        RETURN FALSE;
    END IF;


    -- Busca uma propriedade vinculada ao usuário
    SELECT property_id
      INTO v_property_id
      FROM tb_user_property
     WHERE user_id = p_user_id
     ORDER BY id
     LIMIT 1;


    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;


    -- Verifica se existe dispositivo ativo na propriedade
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_device
         WHERE property_id = v_property_id
           AND is_active = TRUE
    )
    THEN
        RETURN FALSE;
    END IF;


    -- Busca a região e a categoria da propriedade
    SELECT a.region_id, p.classification_id
      INTO v_region_id, v_classification_id
      FROM tb_address a
      JOIN tb_property p
        ON p.address_id = a.id
     WHERE p.id = v_property_id;


    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;


    -- Verifica se existe tarifa cadastrada para a região e categoria
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_region_rate
         WHERE region_id = v_region_id
           AND classification_id = v_classification_id
           AND initial_validity <= p_reference_date
           AND (
                final_validity IS NULL
                OR final_validity >= p_reference_date
           )
    )
    THEN
        RETURN FALSE;
    END IF;


    RETURN TRUE;

END;
$$;

-- Mantém compatibilidade com as chamadas que informam somente o usuário.
CREATE OR REPLACE FUNCTION fn_user_can_estimate(p_user_id INTEGER)
RETURNS BOOLEAN
LANGUAGE sql
AS $$
    SELECT fn_user_can_estimate(p_user_id, CURRENT_DATE);
$$;

