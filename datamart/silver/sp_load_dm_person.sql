CREATE OR REPLACE PROCEDURE silver.sp_load_dm_person()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE silver.dm_person;

    INSERT INTO silver.dm_person (user_id, name, profile_type)
    SELECT
          u.id
        , u.name
        , CASE WHEN uo.user_id IS NOT NULL THEN 'GESTOR' ELSE 'RESIDENCIAL' END
    FROM tb_user u
    LEFT JOIN (SELECT DISTINCT user_id FROM tb_user_organization) uo ON uo.user_id = u.id;

END;
$$;
