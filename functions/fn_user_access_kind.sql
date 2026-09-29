CREATE OR REPLACE FUNCTION fn_user_access_kind(
    p_user_id INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS
    (
        SELECT 1
          FROM tb_user_property
         WHERE user_id = p_user_id
    )
    THEN
        RETURN 'residential';
    END IF;


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
