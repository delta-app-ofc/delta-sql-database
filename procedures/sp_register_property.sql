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