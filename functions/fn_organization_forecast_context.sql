CREATE OR REPLACE FUNCTION fn_organization_forecast_context(
    p_user_id          INTEGER,
    p_property_name    TEXT    DEFAULT NULL,
    p_today            DATE    DEFAULT CURRENT_DATE,
    p_history_days     INTEGER DEFAULT 45,
    p_rate_window_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    access_kind           TEXT,
    match_status          TEXT,
    resolved_property_ids INTEGER[],
    candidate_properties  JSON,
    can_estimate          BOOLEAN,
    history               JSON,
    last_bill_month       DATE,
    last_bill_total_value NUMERIC,
    last_bill_m3_value    NUMERIC,
    effective_rate        NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_access_kind           TEXT;
    v_match_status          TEXT;
    v_resolved_property_ids INTEGER[];
    v_candidate_properties  JSON;
    v_can_estimate          BOOLEAN := FALSE;
    v_history               JSON;
    v_last_bill_month       DATE;
    v_last_bill_total_value NUMERIC;
    v_last_bill_m3_value    NUMERIC;
    v_effective_rate        NUMERIC;
    v_match_count           INTEGER;
BEGIN

    v_access_kind := fn_user_access_kind(p_user_id);


    IF v_access_kind <> 'organizational' THEN

        RETURN QUERY
        SELECT
              v_access_kind
            , 'not_applicable'::TEXT
            , NULL::INTEGER[]
            , NULL::JSON
            , FALSE
            , NULL::JSON
            , NULL::DATE
            , NULL::NUMERIC
            , NULL::NUMERIC
            , NULL::NUMERIC;

        RETURN;

    END IF;


    IF p_property_name IS NULL THEN

        v_match_status := 'resolved';

        SELECT array_agg(op.property_id)
          INTO v_resolved_property_ids
          FROM fn_user_organization_properties(p_user_id) op;

    ELSE

        SELECT COUNT(*)
          INTO v_match_count
          FROM fn_user_organization_properties(p_user_id) op
         WHERE op.name ILIKE '%' || p_property_name || '%';

        IF v_match_count = 1 THEN

            v_match_status := 'resolved';

            SELECT array_agg(op.property_id)
              INTO v_resolved_property_ids
              FROM fn_user_organization_properties(p_user_id) op
             WHERE op.name ILIKE '%' || p_property_name || '%';

        ELSIF v_match_count > 1 THEN

            v_match_status := 'ambiguous';

            SELECT json_agg(json_build_object(
                       'property_id', op.property_id,
                       'name', op.name,
                       'city', op.city,
                       'state', op.state
                   ))
              INTO v_candidate_properties
              FROM fn_user_organization_properties(p_user_id) op
             WHERE op.name ILIKE '%' || p_property_name || '%';

        ELSE

            v_match_status := 'not_found';

            SELECT json_agg(json_build_object(
                       'property_id', op.property_id,
                       'name', op.name,
                       'city', op.city,
                       'state', op.state
                   ))
              INTO v_candidate_properties
              FROM fn_user_organization_properties(p_user_id) op;

        END IF;

    END IF;


    IF v_match_status = 'resolved' THEN

        v_can_estimate := fn_organization_can_estimate(v_resolved_property_ids);

        SELECT json_agg(json_build_object(
                   'full_date', h.full_date,
                   'total_liters', h.total_liters
               ) ORDER BY h.full_date)
          INTO v_history
          FROM fn_organization_consumption_history(
                   v_resolved_property_ids, p_history_days, p_today
               ) h;

        SELECT
              b.reference_month
            , b.total_cost
            , b.total_liters / 1000
          INTO
              v_last_bill_month
            , v_last_bill_total_value
            , v_last_bill_m3_value
          FROM fn_organization_last_billed_period(
                   v_resolved_property_ids, p_today
               ) b;

        v_effective_rate := fn_organization_effective_rate(
                                 v_resolved_property_ids, p_today, p_rate_window_days
                             );

    END IF;


    RETURN QUERY
    SELECT
          v_access_kind
        , v_match_status
        , v_resolved_property_ids
        , v_candidate_properties
        , v_can_estimate
        , v_history
        , v_last_bill_month
        , v_last_bill_total_value
        , v_last_bill_m3_value
        , v_effective_rate;

END;
$$;
