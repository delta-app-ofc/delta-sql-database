CREATE OR REPLACE FUNCTION fn_user_forecast_context(
    p_user_id INTEGER,
    p_today   DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    can_estimate           BOOLEAN,
    region_id              INTEGER,
    classification_id      INTEGER,
    region_rate            NUMERIC,
    last_bill_month        DATE,
    last_bill_total_value  NUMERIC,
    last_bill_m3_value     NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_can_estimate          BOOLEAN;
    v_region_id             INTEGER;
    v_classification_id     INTEGER;
    v_region_rate           NUMERIC;
    v_last_bill_month       DATE;
    v_last_bill_total_value NUMERIC;
    v_last_bill_m3_value    NUMERIC;
BEGIN

    v_can_estimate := fn_user_can_estimate(p_user_id);


    -- Primeira propriedade do usuário (NULL/NULL quando não há nenhuma)
    SELECT c.region_id, c.classification_id
      INTO v_region_id, v_classification_id
      FROM fn_get_user_property_context(p_user_id) c;


    -- Tarifa vigente: fn_get_current_region_rate levanta exceção quando não
    -- há tarifa cadastrada; aqui isso é tratado como "sem tarifa disponível"
    -- (NULL), igual o Python faz hoje, sem propagar o erro
    IF v_region_id IS NOT NULL AND v_classification_id IS NOT NULL THEN

        BEGIN
            v_region_rate := fn_get_current_region_rate(
                                  v_region_id, v_classification_id, p_today
                              );
        EXCEPTION
            WHEN OTHERS THEN
                v_region_rate := NULL;
        END;

    END IF;


    -- Última conta de água registrada (NULL em tudo quando não há nenhuma)
    SELECT b.month, b.total_value, b.m3_value
      INTO v_last_bill_month, v_last_bill_total_value, v_last_bill_m3_value
      FROM tb_last_water_bill b
     WHERE b.user_id = p_user_id
     ORDER BY b.month DESC
     LIMIT 1;


    RETURN QUERY
    SELECT
          v_can_estimate
        , v_region_id
        , v_classification_id
        , v_region_rate
        , v_last_bill_month
        , v_last_bill_total_value
        , v_last_bill_m3_value;

END;
$$;
