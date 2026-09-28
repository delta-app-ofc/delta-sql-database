CREATE OR REPLACE FUNCTION fn_organization_effective_rate(
    p_property_ids  INTEGER[],
    p_today         DATE,
    p_window_days   INTEGER DEFAULT 30
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_liters NUMERIC;
    v_total_cost   NUMERIC;
BEGIN

    -- Tarifa efetiva na janela: não existe um único region_id/classification_id
    -- válido pro conjunto (propriedades de uma organização podem estar em
    -- regiões/categorias diferentes), por isso é calculada, não consultada
    SELECT
          SUM(v.total_liters)
        , SUM(v.cost_value)
      INTO v_total_liters, v_total_cost
      FROM dw.vw_consumption_daily v
     WHERE v.property_id = ANY(p_property_ids)
       AND v.full_date BETWEEN (p_today - (p_window_days - 1)) AND p_today;

    IF v_total_liters IS NULL OR v_total_liters = 0 THEN
        RETURN NULL;
    END IF;

    RETURN v_total_cost / (v_total_liters / 1000);

END;
$$;
