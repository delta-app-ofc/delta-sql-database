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