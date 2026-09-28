CREATE OR REPLACE FUNCTION fn_user_access_kind(
    p_user_id INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN

    -- Usuário com propriedade residencial própria (comportamento antigo, não mexe)
    IF EXISTS
    (
        SELECT 1
          FROM tb_user_property
         WHERE user_id = p_user_id
    )
    THEN
        RETURN 'residential';
    END IF;


    -- Sem propriedade residencial: verifica vínculo com organização
    IF EXISTS
    (
        SELECT 1
          FROM tb_user_organization
         WHERE user_id = p_user_id
    )
    THEN
        RETURN 'organizational';
    END IF;


    RETURN 'none';

END;
$$;
