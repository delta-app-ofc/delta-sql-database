CREATE OR REPLACE PROCEDURE silver.sp_load_dm_person()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE silver.dm_person;

    INSERT INTO silver.dm_person (user_id, name)
    SELECT id, name
    FROM tb_user;

END;
$$;
