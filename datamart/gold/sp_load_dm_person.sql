CREATE OR REPLACE PROCEDURE gold.sp_load_dm_person()
LANGUAGE plpgsql
AS $$
BEGIN

    DELETE FROM gold.dm_person
    WHERE user_id NOT IN (SELECT user_id FROM silver.dm_person);

    INSERT INTO gold.dm_person (user_id, name, profile_type)
    SELECT user_id, name, profile_type
    FROM silver.dm_person
    ON CONFLICT (user_id) DO UPDATE
        SET name         = EXCLUDED.name
          , profile_type = EXCLUDED.profile_type;

END;
$$;
