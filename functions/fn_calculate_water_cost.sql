CREATE OR REPLACE FUNCTION fn_calculate_water_cost(
    p_property_id   INTEGER,
    p_consumption_m3 NUMERIC,
    p_reference_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    property_id     INTEGER,
    region_id       INTEGER,
    consumption_m3  NUMERIC,
    rate_per_m3     NUMERIC,
    estimated_cost  NUMERIC,
    reference_date  DATE
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_region_id  INTEGER;
    v_rate_per_m3 NUMERIC;
BEGIN
    IF p_property_id IS NULL THEN
        RAISE EXCEPTION 'O ID da propriedade é obrigatório';
    END IF;

    IF p_consumption_m3 IS NULL OR p_consumption_m3 < 0 THEN
        RAISE EXCEPTION
            'O consumo deve ser informado e não pode ser negativo';
    END IF;

    IF p_reference_date IS NULL THEN
        RAISE EXCEPTION 'A data de referência é obrigatória';
    END IF;

    SELECT address.region_id
      INTO v_region_id
      FROM tb_property property
      JOIN tb_address address
        ON address.id = property.address_id
     WHERE property.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Propriedade de ID % não encontrada',
            p_property_id;
    END IF;

    SELECT rate.m3_value
      INTO v_rate_per_m3
      FROM tb_region_rate rate
     WHERE rate.region_id = v_region_id
       AND rate.initial_validity <= p_reference_date
       AND (
            rate.final_validity IS NULL
            OR rate.final_validity >= p_reference_date
       )
     ORDER BY rate.initial_validity DESC
     LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Nenhuma tarifa encontrada para a região % na data %',
            v_region_id,
            p_reference_date;
    END IF;

    RETURN QUERY
    SELECT
        p_property_id,
        v_region_id,
        p_consumption_m3,
        v_rate_per_m3,
        ROUND(p_consumption_m3 * v_rate_per_m3, 2),
        p_reference_date;
END;
$$;