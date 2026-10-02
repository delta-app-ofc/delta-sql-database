CREATE OR REPLACE PROCEDURE gold.sp_load_dm_person()
LANGUAGE plpgsql
AS $$
BEGIN

    -- Nunca remove uma pessoa que ainda tem fato vinculado (preserva histórico) -
    -- só limpa dimensão órfã sem nenhuma fatura associada.
    DELETE FROM gold.dm_person
    WHERE user_id NOT IN (SELECT user_id FROM silver.dm_person)
      AND person_key NOT IN (SELECT person_key FROM gold.ft_water_bill_monthly);

    INSERT INTO gold.dm_person (user_id, name)
    SELECT user_id, name
    FROM silver.dm_person
    ON CONFLICT (user_id) DO UPDATE
        SET name = EXCLUDED.name;

END;
$$;
