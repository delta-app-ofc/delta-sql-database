CREATE OR REPLACE FUNCTION fn_get_current_region_rate(
    p_region_id INTEGER,
    p_date DATE
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_m3_value NUMERIC(10,2);
BEGIN

    SELECT m3_value
      INTO v_m3_value
      FROM tb_region_rate
     WHERE region_id = p_region_id
       AND initial_validity <= p_date
       AND (
            final_validity IS NULL
            OR final_validity >= p_date
       )
     LIMIT 1;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Não existe tarifa válida para a região % na data %.',
            p_region_id,
            p_date;
    END IF;


    RETURN v_m3_value;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_property_region(
    p_property_id INTEGER
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_region_name VARCHAR(20);
BEGIN

    SELECT r.name
      INTO v_region_name
      FROM tb_property p
      JOIN tb_address a
        ON a.id = p.address_id
      JOIN tb_region r
        ON r.id = a.region_id
     WHERE p.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Imóvel com id % não encontrado.',
            p_property_id;
    END IF;

    RETURN v_region_name;

END;
$$;

CREATE OR REPLACE FUNCTION fn_user_can_estimate(
    p_user_id INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_id INTEGER;
    v_region_id INTEGER;
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


    -- Busca a região da propriedade
    SELECT region_id
      INTO v_region_id
      FROM tb_address a
      JOIN tb_property p
        ON p.address_id = a.id
     WHERE p.id = v_property_id;


    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;


    -- Verifica se existe tarifa cadastrada para a região
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_region_rate
         WHERE region_id = v_region_id
           AND initial_validity <= CURRENT_DATE
           AND (
                final_validity IS NULL
                OR final_validity >= CURRENT_DATE
           )
    )
    THEN
        RETURN FALSE;
    END IF;


    RETURN TRUE;

END;
$$;

CREATE OR REPLACE FUNCTION fn_user_is_active(
    p_user_id INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active
    INTO v_is_active
    FROM tb_user
    WHERE id = p_user_id;

    IF NOT FOUND THEN 
        RAISE EXCEPTION 'Usuário com id % não encontrado.', p_user_id;
    END IF;

    RETURN v_is_active;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_change_region_rate(
    p_region_id INTEGER,
    p_new_rate NUMERIC(10,2),
    p_initial_validity DATE
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Verifica se a região existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_region
         WHERE id = p_region_id
    )
    THEN
        RAISE EXCEPTION
            'Região com id % não encontrada.',
            p_region_id;
    END IF;


    -- Valida o valor da tarifa
    IF p_new_rate <= 0 THEN
        RAISE EXCEPTION
            'O valor da tarifa deve ser maior que zero.';
    END IF;


    -- Fecha a tarifa atualmente vigente
    UPDATE tb_region_rate
       SET final_validity = p_initial_validity - INTERVAL '1 day'
     WHERE region_id = p_region_id
       AND final_validity IS NULL;


    -- Insere a nova tarifa
    INSERT INTO tb_region_rate
    (
        region_id,
        m3_value,
        initial_validity,
        final_validity
    )
    VALUES
    (
        p_region_id,
        p_new_rate,
        p_initial_validity,
        NULL
    );


END;
$$;

CREATE OR REPLACE PROCEDURE sp_change_region_rate(
    p_region_id INTEGER,
    p_new_rate NUMERIC(10,2),
    p_initial_validity DATE
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Verifica se a região existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_region
         WHERE id = p_region_id
    )
    THEN
        RAISE EXCEPTION
            'Região com id % não encontrada.',
            p_region_id;
    END IF;


    -- Valida o valor da tarifa
    IF p_new_rate <= 0 THEN
        RAISE EXCEPTION
            'O valor da tarifa deve ser maior que zero.';
    END IF;


    -- Fecha a tarifa atualmente vigente
    UPDATE tb_region_rate
       SET final_validity = p_initial_validity - INTERVAL '1 day'
     WHERE region_id = p_region_id
       AND final_validity IS NULL;


    -- Insere a nova tarifa
    INSERT INTO tb_region_rate
    (
        region_id,
        m3_value,
        initial_validity,
        final_validity
    )
    VALUES
    (
        p_region_id,
        p_new_rate,
        p_initial_validity,
        NULL
    );


END;
$$;

CREATE OR REPLACE PROCEDURE sp_disable_user(
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN


    -- Verifica se o usuário existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_user
         WHERE id = p_user_id
    )
    THEN

        RAISE EXCEPTION
            'Usuário % não encontrado.',
            p_user_id;

    END IF;



    -- Desativa o usuário
    UPDATE tb_user
       SET is_active = FALSE
     WHERE id = p_user_id;



    -- Desativa dispositivos das propriedades do usuário
    UPDATE tb_device
       SET is_active = FALSE
     WHERE property_id IN
     (
        SELECT property_id
          FROM tb_user_property
         WHERE user_id = p_user_id
     );


END;
$$;

CREATE OR REPLACE PROCEDURE sp_register_property(
    p_user_id INTEGER,
    p_name VARCHAR(100),
    p_type VARCHAR(20),
    p_classification VARCHAR(20),
    p_address_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_id INTEGER;
BEGIN


    -- Verifica se o usuário existe e está ativo
    IF NOT fn_user_is_active(p_user_id) THEN

        RAISE EXCEPTION
            'Usuário % inexistente ou inativo.',
            p_user_id;

    END IF;



    -- Verifica se o endereço existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_address
         WHERE id = p_address_id
    )
    THEN

        RAISE EXCEPTION
            'Endereço % não encontrado.',
            p_address_id;

    END IF;



    -- Insere a propriedade
    INSERT INTO tb_property
    (
        name,
        type,
        classification,
        address_id
    )
    VALUES
    (
        p_name,
        p_type,
        p_classification,
        p_address_id
    )
    RETURNING id INTO v_property_id;



    -- Cria vínculo entre usuário e propriedade
    INSERT INTO tb_user_property
    (
        user_id,
        property_id
    )
    VALUES
    (
        p_user_id,
        v_property_id
    );


END;
$$;