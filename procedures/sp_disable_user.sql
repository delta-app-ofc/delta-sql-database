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