CREATE OR REPLACE PROCEDURE sp_register_user_access(
    p_user_id INTEGER,
    p_access_channel VARCHAR(20) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- fn_user_is_active já lança exceção se o usuário não existir
    IF NOT fn_user_is_active(p_user_id) THEN
        RAISE EXCEPTION 'Usuário % está inativo e não pode ter acesso registrado.', p_user_id;
    END IF;

    INSERT INTO tb_user_access_log (user_id, access_channel)
    VALUES (p_user_id, p_access_channel);

END;
$$;
