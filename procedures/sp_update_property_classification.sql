CREATE OR REPLACE PROCEDURE sp_update_property_classification(
    p_property_id INTEGER,
    p_classification VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_classification_id INTEGER;
BEGIN


    -- Verifica se o imóvel existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_property
         WHERE id = p_property_id
    )
    THEN

        RAISE EXCEPTION
            'Imóvel % não encontrado.',
            p_property_id;

    END IF;



    -- Resolve o nome da classificação pro id correspondente
    SELECT id
      INTO v_classification_id
      FROM tb_property_classification
     WHERE name = p_classification;

    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Classificação % não encontrada.',
            p_classification;

    END IF;



    -- Atualiza a classificação (o trigger trg_log_property audita a mudança)
    UPDATE tb_property
       SET classification_id = v_classification_id
     WHERE id = p_property_id;

    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Imóvel % não encontrado.',
            p_property_id;

    END IF;


END;
$$;
