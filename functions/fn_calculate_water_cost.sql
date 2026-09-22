CREATE OR REPLACE FUNCTION fn_calculate_water_cost(
    p_property_id   INTEGER,
    p_consumption_m3 NUMERIC,
    p_reference_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    property_id    INTEGER,
    region_id      INTEGER,
    consumption_m3 NUMERIC,
    rate_per_m3    NUMERIC,
    estimated_cost NUMERIC,
    reference_date DATE
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF p_property_id IS NULL THEN
        RAISE EXCEPTION 'O ID da propriedade é obrigatório';
    END IF;

    IF p_consumption_m3 IS NULL OR p_consumption_m3 < 0 THEN
        RAISE EXCEPTION 'O consumo deve ser informado e não pode ser negativo';
    END IF;

    IF p_reference_date IS NULL THEN
        RAISE EXCEPTION 'A data de referência é obrigatória';
    END IF;

    PERFORM 1
    FROM tb_property tp
    WHERE tp.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Propriedade de ID % não encontrada', p_property_id;
    END IF;

    RETURN QUERY
    SELECT
        tp.id,
        tr.id,
        p_consumption_m3,
        trr.m3_value,
        ROUND(p_consumption_m3 * trr.m3_value, 2),
        p_reference_date
    FROM tb_property tp
    JOIN tb_address a
        ON a.id = tp.address_id
    JOIN tb_region tr
        ON tr.id = a.region_id
    JOIN tb_region_rate trr
        ON trr.region_id = tr.id
       AND trr.classification_id = tp.classification_id
    WHERE tp.id = p_property_id
      AND trr.initial_validity <= p_reference_date
      AND (
          trr.final_validity IS NULL
          OR trr.final_validity >= p_reference_date
      )
    ORDER BY trr.initial_validity DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Nenhuma tarifa encontrada para a propriedade % na data %',
            p_property_id, p_reference_date;
    END IF;
END;
$$;