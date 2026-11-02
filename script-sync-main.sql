-- Sincroniza um banco já em uso com a main, sem apagar dados de negócio.
-- Pode ser reexecutado. Não mexe em tabelas de dados, exceto remover tb_device_credential.
--
-- O que faz:
--   1. Remove tb_device_credential (e suas linhas no catálogo), que não faz parte do schema.
--   2. Remove a versão antiga de sp_register_property (5 parâmetros).
--   3. Reaplica Functions, Procedures e triggers de hábitos (script-optimization.sql).
--   4. Recria as views do schema dw (inclui dw.vw_audit_history_chain).
--   5. Cria o índice da cadeia de auditoria, se não existir.

BEGIN;

DROP TABLE IF EXISTS tb_device_credential CASCADE;
DELETE FROM tb_data_catalog WHERE table_name = 'tb_device_credential';

DO $do$
DECLARE
    v_proc REGPROCEDURE;
BEGIN
    FOR v_proc IN
        SELECT p.oid::regprocedure
          FROM pg_proc p
         WHERE p.pronamespace = 'public'::regnamespace
           AND p.proname = 'sp_register_property'
           AND p.pronargs = 5
    LOOP
        EXECUTE 'DROP PROCEDURE ' || v_proc;
    END LOOP;
END
$do$;

-- Functions, Procedures e triggers (de script-optimization.sql)
CREATE OR REPLACE FUNCTION fn_get_current_region_rate(
    p_region_id INTEGER,
    p_classification_id INTEGER,
    p_date DATE
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_m3_value NUMERIC(10,2);
BEGIN

    SELECT m3_value
      INTO v_m3_value
      FROM tb_region_rate
     WHERE region_id = p_region_id
       AND classification_id = p_classification_id
       AND initial_validity <= p_date
       AND (
            final_validity IS NULL
            OR final_validity >= p_date
       )
     ORDER BY initial_validity DESC
     LIMIT 1;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Não existe tarifa válida para a região %, categoria % na data %.',
            p_region_id,
            p_classification_id,
            p_date;
    END IF;


    RETURN v_m3_value;

END;
$$;
CREATE OR REPLACE FUNCTION fn_get_dau(
    p_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_dau INTEGER;
BEGIN

    IF p_date IS NULL THEN
        RAISE EXCEPTION 'A data não pode ser nula.';
    END IF;

    SELECT COUNT(DISTINCT user_id)
    INTO v_dau
    FROM tb_user_access_log
    WHERE accessed_at::DATE = p_date;

    RETURN v_dau;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_property_classification(
    p_property_id INTEGER
)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
DECLARE
    v_classification VARCHAR(50);
BEGIN

    SELECT pc.name
      INTO v_classification
      FROM tb_property p
      JOIN tb_property_classification pc
        ON pc.id = p.classification_id
     WHERE p.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Imóvel com id % não encontrado.',
            p_property_id;
    END IF;

    RETURN v_classification;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_property_classification_group(
    p_property_id INTEGER
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_group_name VARCHAR(20);
BEGIN

    SELECT pc.group_name
      INTO v_group_name
      FROM tb_property p
      JOIN tb_property_classification pc
        ON pc.id = p.classification_id
     WHERE p.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Imóvel com id % não encontrado.',
            p_property_id;
    END IF;

    RETURN v_group_name;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_property_region(
    p_property_id INTEGER
)
RETURNS VARCHAR(30)
LANGUAGE plpgsql
AS $$
DECLARE
    v_region_name VARCHAR(30);
BEGIN

    SELECT r.name
      INTO v_region_name
      FROM tb_property p
      JOIN tb_address a
        ON a.id = p.address_id
      JOIN tb_region r
        ON r.id = a.region_id
     WHERE p.id = p_property_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Imóvel com id % não encontrado.',
            p_property_id;
    END IF;

    RETURN v_region_name;

END;
$$;
CREATE OR REPLACE FUNCTION fn_user_can_estimate(
    p_user_id INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_id INTEGER;
    v_region_id INTEGER;
    v_classification_id INTEGER;
BEGIN

    -- Verifica se o usuário existe e está ativo
    IF NOT fn_user_is_active(p_user_id) THEN
        RETURN FALSE;
    END IF;


    -- Busca uma propriedade vinculada ao usuário
    SELECT property_id
      INTO v_property_id
      FROM tb_user_property
     WHERE user_id = p_user_id
     LIMIT 1;


    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;


    -- Verifica se existe dispositivo ativo na propriedade
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_device
         WHERE property_id = v_property_id
           AND is_active = TRUE
    )
    THEN
        RETURN FALSE;
    END IF;


    -- Busca a região e a categoria da propriedade
    SELECT a.region_id, p.classification_id
      INTO v_region_id, v_classification_id
      FROM tb_address a
      JOIN tb_property p
        ON p.address_id = a.id
     WHERE p.id = v_property_id;


    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;


    -- Verifica se existe tarifa cadastrada para a região e categoria
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_region_rate
         WHERE region_id = v_region_id
           AND classification_id = v_classification_id
           AND initial_validity <= CURRENT_DATE
           AND (
                final_validity IS NULL
                OR final_validity >= CURRENT_DATE
           )
    )
    THEN
        RETURN FALSE;
    END IF;


    RETURN TRUE;

END;
$$;


CREATE OR REPLACE FUNCTION fn_user_is_active(
    p_user_id INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active
    INTO v_is_active
    FROM tb_user
    WHERE id = p_user_id;

    IF NOT FOUND THEN 
        RAISE EXCEPTION 'Usuário com id % não encontrado.', p_user_id;
    END IF;

    RETURN v_is_active;

END;
$$;
CREATE OR REPLACE PROCEDURE sp_change_region_rate(
    p_region_id INTEGER,
    p_classification_id INTEGER,
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


    -- Verifica se a categoria existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_property_classification
         WHERE id = p_classification_id
    )
    THEN
        RAISE EXCEPTION
            'Categoria com id % não encontrada.',
            p_classification_id;
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
       AND classification_id = p_classification_id
       AND final_validity IS NULL;


    -- Insere a nova tarifa
    INSERT INTO tb_region_rate
    (
        region_id,
        classification_id,
        m3_value,
        initial_validity,
        final_validity
    )
    VALUES
    (
        p_region_id,
        p_classification_id,
        p_new_rate,
        p_initial_validity,
        NULL
    );


END;
$$;
CREATE OR REPLACE PROCEDURE sp_disable_user(
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN


    -- Verifica se o usuário existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_user
         WHERE id = p_user_id
    )
    THEN

        RAISE EXCEPTION
            'Usuário % não encontrado.',
            p_user_id;

    END IF;



    -- Desativa o usuário
    UPDATE tb_user
       SET is_active = FALSE
     WHERE id = p_user_id;



    -- Desativa dispositivos das propriedades do usuário
    UPDATE tb_device
       SET is_active = FALSE
     WHERE property_id IN
     (
        SELECT property_id
          FROM tb_user_property
         WHERE user_id = p_user_id
     );


END;
$$;
CREATE OR REPLACE PROCEDURE sp_register_property(
    IN p_user_id INTEGER,
    IN p_name VARCHAR(100),
    IN p_type VARCHAR(20),
    IN p_classification VARCHAR(50),
    IN p_address_id INTEGER,
    IN p_organization_id INTEGER,
    IN p_built_area_m2 NUMERIC(10,2),
    OUT v_property_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_classification_id INTEGER;
BEGIN


    -- Verifica se o usuário existe e está ativo
    IF NOT fn_user_is_active(p_user_id) THEN

        RAISE EXCEPTION
            'Usuário % inexistente ou inativo.',
            p_user_id;

    END IF;



    -- Verifica se o endereço existe
    IF NOT EXISTS
    (
        SELECT 1
          FROM tb_address
         WHERE id = p_address_id
    )
    THEN

        RAISE EXCEPTION
            'Endereço % não encontrado.',
            p_address_id;

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



    -- Verifica se a organização existe, quando informada (imóvel comercial/industrial)
    IF p_organization_id IS NOT NULL AND NOT EXISTS
    (
        SELECT 1
          FROM tb_organization
         WHERE id = p_organization_id
    )
    THEN

        RAISE EXCEPTION
            'Organização % não encontrada.',
            p_organization_id;

    END IF;



    -- Insere a propriedade
    INSERT INTO tb_property
    (
        name,
        type,
        classification_id,
        address_id,
        organization_id,
        built_area_m2
    )
    VALUES
    (
        p_name,
        p_type,
        v_classification_id,
        p_address_id,
        p_organization_id,
        p_built_area_m2
    )
    RETURNING id INTO v_property_id;



    -- Cria vínculo entre usuário e propriedade
    INSERT INTO tb_user_property
    (
        user_id,
        property_id
    )
    VALUES
    (
        p_user_id,
        v_property_id
    );


END;
$$;

CREATE OR REPLACE PROCEDURE sp_register_user_access(
    p_user_id INTEGER,
    p_access_channel VARCHAR(20) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- fn_user_is_active já lança exceção se o usuário não existir
    IF NOT fn_user_is_active(p_user_id) THEN
        RAISE EXCEPTION 'Usuário % está inativo e não pode ter acesso registrado.', p_user_id;
    END IF;

    INSERT INTO tb_user_access_log (user_id, access_channel)
    VALUES (p_user_id, p_access_channel);

END;
$$;

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

CREATE OR REPLACE FUNCTION fn_user_access_kind(
    p_user_id INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS
    (
        SELECT 1
          FROM tb_user_property
         WHERE user_id = p_user_id
    )
    THEN
        RETURN 'residential';
    END IF;


    IF EXISTS
    (
        SELECT 1
          FROM tb_user_organization
         WHERE user_id = p_user_id
    )
    THEN
        RETURN 'organizational';
    END IF;


    RETURN 'none';

END;
$$;

CREATE OR REPLACE FUNCTION fn_user_organization_properties(
    p_user_id INTEGER
)
RETURNS TABLE (
    property_id INTEGER,
    name        VARCHAR,
    city        VARCHAR,
    state       VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          p.id
        , p.name
        , a.city
        , a.state
      FROM tb_user_organization uo
      JOIN tb_property p
        ON p.organization_id = uo.organization_id
      JOIN tb_address a
        ON a.id = p.address_id
     WHERE uo.user_id = p_user_id;

END;
$$;

CREATE OR REPLACE FUNCTION fn_user_authorized_property_ids(
    p_user_id      INTEGER,
    p_property_ids INTEGER[]
)
RETURNS INTEGER[]
LANGUAGE plpgsql
AS $$
DECLARE
    v_authorized INTEGER[];
BEGIN

    SELECT COALESCE(ARRAY_AGG(p.id), ARRAY[]::INTEGER[])
      INTO v_authorized
      FROM tb_user_organization uo
      JOIN tb_property p
        ON p.organization_id = uo.organization_id
     WHERE uo.user_id = p_user_id
       AND p.id = ANY(p_property_ids);

    RETURN v_authorized;

END;
$$;

DROP FUNCTION IF EXISTS fn_organization_can_estimate(INTEGER[]);

CREATE OR REPLACE FUNCTION fn_organization_can_estimate(
    p_user_id      INTEGER,
    p_property_ids INTEGER[]
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
BEGIN

    RETURN EXISTS
    (
        SELECT 1
          FROM gold.ft_consumption_daily f
          JOIN gold.dm_property dp
            ON dp.property_key = f.property_key
         WHERE dp.property_id = ANY(v_property_ids)
    );

END;
$$;

DROP FUNCTION IF EXISTS fn_organization_consumption_history(INTEGER[], INTEGER, DATE);

CREATE OR REPLACE FUNCTION fn_organization_consumption_history(
    p_user_id      INTEGER,
    p_property_ids INTEGER[],
    p_days         INTEGER,
    p_today        DATE
)
RETURNS TABLE (
    full_date    DATE,
    total_liters NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
BEGIN

    RETURN QUERY
    SELECT
          v.full_date
        , SUM(v.total_liters) AS total_liters
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
       AND v.full_date BETWEEN (p_today - (p_days - 1)) AND p_today
     GROUP BY v.full_date
     ORDER BY v.full_date;

END;
$$;

DROP FUNCTION IF EXISTS fn_organization_last_billed_period(INTEGER[], DATE);

CREATE OR REPLACE FUNCTION fn_organization_last_billed_period(
    p_user_id      INTEGER,
    p_property_ids INTEGER[],
    p_today        DATE
)
RETURNS TABLE (
    reference_month DATE,
    total_liters    NUMERIC,
    total_cost      NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
    v_last_closed_month DATE := DATE_TRUNC('month', p_today) - INTERVAL '1 month';
BEGIN

    RETURN QUERY
    SELECT
          v_last_closed_month
        , SUM(v.total_liters)
        , SUM(v.cost_value)
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
       AND DATE_TRUNC('month', v.full_date) = v_last_closed_month
    HAVING SUM(v.total_liters) IS NOT NULL;

    IF FOUND THEN
        RETURN;
    END IF;


    RETURN QUERY
    SELECT
          DATE_TRUNC('month', MAX(v.full_date))::DATE
        , SUM(v.total_liters)
        , SUM(v.cost_value)
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
    HAVING SUM(v.total_liters) IS NOT NULL;

END;
$$;

DROP FUNCTION IF EXISTS fn_organization_effective_rate(INTEGER[], DATE, INTEGER);

CREATE OR REPLACE FUNCTION fn_organization_effective_rate(
    p_user_id      INTEGER,
    p_property_ids  INTEGER[],
    p_today         DATE,
    p_window_days   INTEGER DEFAULT 30
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_property_ids INTEGER[] := fn_user_authorized_property_ids(p_user_id, p_property_ids);
    v_total_liters NUMERIC;
    v_total_cost   NUMERIC;
BEGIN

    SELECT
          SUM(v.total_liters)
        , SUM(v.cost_value)
      INTO v_total_liters, v_total_cost
      FROM dw.vw_ft_consumption_daily v
     WHERE v.property_id = ANY(v_property_ids)
       AND v.full_date BETWEEN (p_today - (p_window_days - 1)) AND p_today;

    IF v_total_liters IS NULL OR v_total_liters = 0 THEN
        RETURN NULL;
    END IF;

    RETURN v_total_cost / (v_total_liters / 1000);

END;
$$;

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

        v_can_estimate := fn_organization_can_estimate(p_user_id, v_resolved_property_ids);

        SELECT json_agg(json_build_object(
                   'full_date', h.full_date,
                   'total_liters', h.total_liters
               ) ORDER BY h.full_date)
          INTO v_history
          FROM fn_organization_consumption_history(
                   p_user_id, v_resolved_property_ids, p_history_days, p_today
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
                   p_user_id, v_resolved_property_ids, p_today
               ) b;

        v_effective_rate := fn_organization_effective_rate(
                                 p_user_id, v_resolved_property_ids, p_today, p_rate_window_days
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

CREATE OR REPLACE FUNCTION fn_get_user_property_context(
    p_user_id INTEGER
)
RETURNS TABLE (
    region_id         INTEGER,
    classification_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          a.region_id
        , p.classification_id
      FROM tb_user_property up
      JOIN tb_property p
        ON p.id = up.property_id
      JOIN tb_address a
        ON a.id = p.address_id
     WHERE up.user_id = p_user_id
     ORDER BY up.id
     LIMIT 1;

END;
$$;

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


    SELECT c.region_id, c.classification_id
      INTO v_region_id, v_classification_id
      FROM fn_get_user_property_context(p_user_id) c;


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

CREATE OR REPLACE FUNCTION fn_user_habits(
    p_user_id INTEGER
)
RETURNS TABLE (
    name             VARCHAR,
    category         VARCHAR,
    frequency        INTEGER,
    days             VARCHAR[],
    start_time       TIME,
    end_time         TIME,
    estimated_liters NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          h.name
        , h.category
        , uh.frequency
        , COALESCE(
              array_agg(d.name ORDER BY d.id) FILTER (WHERE d.id IS NOT NULL)
            , ARRAY[]::VARCHAR[]
          )
        , uh.start_time
        , uh.end_time
        , uh.estimated_liters
      FROM tb_user_habit uh
      JOIN tb_habit h
        ON h.id = uh.habit_id
      LEFT JOIN tb_user_habit_day uhd
        ON uhd.user_habit_id = uh.id
      LEFT JOIN tb_day_of_week d
        ON d.id = uhd.day_of_week_id
     WHERE uh.user_id = p_user_id
     GROUP BY uh.id, h.name, h.category
     ORDER BY h.name;

END;
$$;

CREATE OR REPLACE FUNCTION fn_user_habits_by_day(
    p_user_id INTEGER,
    p_day     VARCHAR
)
RETURNS TABLE (
    name             VARCHAR,
    frequency        INTEGER,
    start_time       TIME,
    end_time         TIME,
    estimated_liters NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          h.name
        , uh.frequency
        , uh.start_time
        , uh.end_time
        , uh.estimated_liters
      FROM tb_user_habit uh
      JOIN tb_habit h
        ON h.id = uh.habit_id
      JOIN tb_user_habit_day uhd
        ON uhd.user_habit_id = uh.id
      JOIN tb_day_of_week d
        ON d.id = uhd.day_of_week_id
     WHERE uh.user_id = p_user_id
       AND d.name = UPPER(p_day)
     ORDER BY uh.start_time NULLS LAST, h.name;

END;
$$;

CREATE OR REPLACE FUNCTION fn_user_location(
    p_user_id INTEGER
)
RETURNS TABLE (
    city  VARCHAR,
    state VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          a.city
        , a.state
      FROM tb_user_property up
      JOIN tb_property p
        ON p.id = up.property_id
      JOIN tb_address a
        ON a.id = p.address_id
     WHERE up.user_id = p_user_id
     ORDER BY up.id
     LIMIT 1;

END;
$$;

DROP FUNCTION IF EXISTS fn_create_user_habit(INTEGER, VARCHAR, INTEGER, VARCHAR[]);

CREATE OR REPLACE FUNCTION fn_create_user_habit(
    p_user_id    INTEGER,
    p_habit_name VARCHAR,
    p_frequency  INTEGER,
    p_days       VARCHAR[] DEFAULT ARRAY[]::VARCHAR[],
    p_start_time TIME      DEFAULT NULL,
    p_end_time   TIME      DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_habit_id      INTEGER;
    v_user_habit_id INTEGER;
    v_days_count    INTEGER;
    v_inserted      INTEGER;
BEGIN

    SELECT h.id
      INTO v_habit_id
      FROM tb_habit h
     WHERE h.name = UPPER(p_habit_name);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hábito % não existe no catálogo.', p_habit_name;
    END IF;


    -- O mesmo hábito pode ser cadastrado mais de uma vez (horários ou dias diferentes).
    -- Conflito de dia + horário é barrado pela trigger trg_check_user_habit_day_conflict.
    INSERT INTO tb_user_habit (user_id, habit_id, frequency, start_time, end_time)
    VALUES (p_user_id, v_habit_id, p_frequency, p_start_time, p_end_time)
    RETURNING id INTO v_user_habit_id;


    SELECT COUNT(DISTINCT UPPER(x))
      INTO v_days_count
      FROM unnest(p_days) AS x;

    INSERT INTO tb_user_habit_day (user_habit_id, day_of_week_id)
    SELECT v_user_habit_id, d.id
      FROM tb_day_of_week d
     WHERE d.name IN (SELECT UPPER(x) FROM unnest(p_days) AS x);

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    IF v_inserted <> v_days_count THEN
        RAISE EXCEPTION 'Dia da semana inválido em %.', p_days;
    END IF;


    RETURN v_user_habit_id;

END;
$$;

-- Regra: o mesmo usuário não pode ter o mesmo hábito, no mesmo dia da semana,
-- com o mesmo horário de início (NULL conta como "sem horário", igual a outro NULL).

-- Dispara ao inserir/alterar um dia em tb_user_habit_day.
CREATE OR REPLACE FUNCTION fn_check_user_habit_day_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS (
        SELECT 1
          FROM tb_user_habit me
          JOIN tb_user_habit other
            ON other.user_id = me.user_id
           AND other.habit_id = me.habit_id
           AND other.id <> me.id
           AND other.start_time IS NOT DISTINCT FROM me.start_time
          JOIN tb_user_habit_day other_day
            ON other_day.user_habit_id = other.id
           AND other_day.day_of_week_id = NEW.day_of_week_id
         WHERE me.id = NEW.user_habit_id
    ) THEN
        RAISE EXCEPTION 'O usuário já possui esse hábito nesse dia e horário.';
    END IF;

    RETURN NEW;

END;
$$;

-- Dispara ao trocar o hábito ou o horário em tb_user_habit (os dias já existem).
CREATE OR REPLACE FUNCTION fn_check_user_habit_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS (
        SELECT 1
          FROM tb_user_habit other
          JOIN tb_user_habit_day other_day
            ON other_day.user_habit_id = other.id
          JOIN tb_user_habit_day my_day
            ON my_day.user_habit_id = NEW.id
           AND my_day.day_of_week_id = other_day.day_of_week_id
         WHERE other.user_id = NEW.user_id
           AND other.habit_id = NEW.habit_id
           AND other.id <> NEW.id
           AND other.start_time IS NOT DISTINCT FROM NEW.start_time
    ) THEN
        RAISE EXCEPTION 'O usuário já possui esse hábito nesse dia e horário.';
    END IF;

    RETURN NEW;

END;
$$;

DROP TRIGGER IF EXISTS trg_check_user_habit_day_conflict ON tb_user_habit_day;
CREATE TRIGGER trg_check_user_habit_day_conflict
BEFORE INSERT OR UPDATE
ON tb_user_habit_day
FOR EACH ROW
EXECUTE FUNCTION fn_check_user_habit_day_conflict();

DROP TRIGGER IF EXISTS trg_check_user_habit_conflict ON tb_user_habit;
CREATE TRIGGER trg_check_user_habit_conflict
BEFORE UPDATE OF user_id, habit_id, start_time
ON tb_user_habit
FOR EACH ROW
EXECUTE FUNCTION fn_check_user_habit_conflict();


-- Views do schema dw (de script-datamart.sql)
CREATE SCHEMA IF NOT EXISTS dw;

DROP VIEW IF EXISTS dw.vw_ft_consumption_daily;
DROP VIEW IF EXISTS dw.vw_ft_property_ranking;
DROP VIEW IF EXISTS dw.vw_ft_monthly_variation;
DROP VIEW IF EXISTS dw.vw_ft_consumption_distribution;
DROP VIEW IF EXISTS dw.vw_ft_capex_comparison;
DROP VIEW IF EXISTS dw.vw_ft_residential_efficiency_ranking;
DROP VIEW IF EXISTS dw.vw_audit_history_chain;
DROP VIEW IF EXISTS dw.vw_ft_alert;
DROP VIEW IF EXISTS dw.vw_ft_user_goal;

CREATE OR REPLACE VIEW dw.vw_ft_consumption_daily AS
WITH staging_consumption AS (
    SELECT
          f.property_key
        , dp.property_id
        , dp.name           AS property_name
        , dd.full_date
        , f.total_liters
        , f.cost_value
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    JOIN gold.dm_date dd     ON dd.date_key = f.date_key
)
SELECT
      property_id
    , property_name
    , full_date
    , total_liters
    , cost_value
    , SUM(total_liters) OVER (
          PARTITION BY property_id ORDER BY full_date
          ROWS UNBOUNDED PRECEDING
      ) AS running_total_liters
    , AVG(total_liters) OVER (
          PARTITION BY property_id ORDER BY full_date
          ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ) AS moving_avg_7d_liters
FROM staging_consumption;

CREATE OR REPLACE VIEW dw.vw_ft_property_ranking AS
WITH agg_consumption AS (
    SELECT
          dp.property_id
        , dp.name             AS property_name
        , dp.built_area_m2
        , SUM(f.total_liters) AS total_liters
        , SUM(f.cost_value)   AS total_cost
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    WHERE dp.built_area_m2 IS NOT NULL
    GROUP BY dp.property_id, dp.name, dp.built_area_m2
),
final_ranking AS (
    SELECT
          property_id
        , property_name
        , total_liters
        , total_cost
        , ROUND(total_liters / built_area_m2, 2) AS liters_per_m2
    FROM agg_consumption
)
SELECT
      property_id
    , property_name
    , total_liters
    , total_cost
    , liters_per_m2
    , RANK()         OVER (ORDER BY liters_per_m2 ASC)  AS rank_efficiency
    , DENSE_RANK()   OVER (ORDER BY total_cost DESC)    AS rank_cost
    , NTILE(4)       OVER (ORDER BY liters_per_m2)      AS consumption_quartile
    , PERCENT_RANK() OVER (ORDER BY liters_per_m2)      AS consumption_percent_rank
FROM final_ranking;

CREATE OR REPLACE VIEW dw.vw_ft_monthly_variation AS
WITH staging_monthly AS (
    SELECT
          dp.property_id
        , dp.name AS property_name
        , DATE_TRUNC('month', dd.full_date)::DATE AS reference_month
        , SUM(f.total_liters) AS total_liters
    FROM gold.ft_consumption_daily f
    JOIN gold.dm_property dp ON dp.property_key = f.property_key
    JOIN gold.dm_date dd     ON dd.date_key = f.date_key
    GROUP BY dp.property_id, dp.name, DATE_TRUNC('month', dd.full_date)
),
final_variation AS (
    SELECT
          property_id
        , property_name
        , reference_month
        , total_liters
        , LAG(total_liters) OVER (PARTITION BY property_id ORDER BY reference_month) AS previous_month_liters
    FROM staging_monthly
)
SELECT
      property_id
    , property_name
    , reference_month
    , total_liters
    , previous_month_liters
    , ROUND(
          (total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100
        , 1
      ) AS variation_pct
FROM final_variation;

CREATE OR REPLACE VIEW dw.vw_ft_consumption_distribution AS
WITH staging_daily_totals AS (
    SELECT
          f.property_key
        , f.total_liters
    FROM gold.ft_consumption_daily f
),
agg_stats AS (
    SELECT
          MIN(total_liters) AS min_liters
        , MAX(total_liters) AS max_liters
        , PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_liters) AS q1_liters
        , PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_liters) AS median_liters
        , PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_liters) AS q3_liters
    FROM staging_daily_totals
)
SELECT
      s.property_key
    , s.total_liters
    , NTILE(5) OVER (ORDER BY s.total_liters) AS distribution_bucket
    , a.min_liters
    , a.q1_liters
    , a.median_liters
    , a.q3_liters
    , a.max_liters
FROM staging_daily_totals s
CROSS JOIN agg_stats a;

CREATE OR REPLACE VIEW dw.vw_ft_capex_comparison AS
WITH staging_scenario AS (
    SELECT
          scenario_id
        , name
        , investment_value
        , reduction_pct
        , annual_savings_value
        , payback_months
    FROM gold.ft_investment_scenario
)
SELECT
      scenario_id
    , name
    , investment_value
    , reduction_pct
    , annual_savings_value
    , payback_months
    , RANK() OVER (ORDER BY payback_months ASC NULLS LAST) AS rank_by_payback
FROM staging_scenario;

CREATE OR REPLACE VIEW dw.vw_ft_residential_efficiency_ranking AS
WITH staging_bill AS (
    SELECT
          dpe.user_id
        , dpe.name AS person_name
        , dd.full_date AS reference_month
        , f.m3_value
        , f.total_value
    FROM gold.ft_water_bill_monthly f
    JOIN gold.dm_person dpe ON dpe.person_key = f.person_key
    JOIN gold.dm_date dd    ON dd.date_key = f.date_key
)
SELECT
      user_id
    , person_name
    , reference_month
    , m3_value
    , total_value
    , RANK()         OVER (PARTITION BY reference_month ORDER BY m3_value ASC) AS rank_efficiency
    , PERCENT_RANK() OVER (PARTITION BY reference_month ORDER BY m3_value)     AS consumption_percent_rank
FROM staging_bill;

CREATE OR REPLACE VIEW dw.vw_audit_history_chain AS
WITH RECURSIVE chain AS (
    SELECT
          id
        , region_rate_id
        , m3_value
        , operation
        , executed_by
        , executed_at
        , previous_log_id
        , 1 AS level
    FROM tb_log_region_rate
    WHERE previous_log_id IS NULL

    UNION ALL

    SELECT
          l.id
        , l.region_rate_id
        , l.m3_value
        , l.operation
        , l.executed_by
        , l.executed_at
        , l.previous_log_id
        , c.level + 1
    FROM tb_log_region_rate l
    JOIN chain c ON l.previous_log_id = c.id
)
SELECT
      id AS log_id
    , region_rate_id
    , m3_value
    , operation
    , executed_by
    , executed_at
    , level
FROM chain;

CREATE OR REPLACE VIEW dw.vw_ft_alert AS
SELECT
      fa.alert_key
    , dp.property_id
    , dp.name           AS property_name
    , dpe.user_id
    , dpe.name          AS person_name
    , dd.full_date      AS alert_date
    , fa.device_id
    , fa.alert_type
    , fa.severity
    , fa.triggered_at
    , fa.resolved_at
    , ROUND(EXTRACT(EPOCH FROM (fa.resolved_at - fa.triggered_at)) / 60.0, 1) AS resolution_minutes
FROM gold.ft_alert fa
JOIN gold.dm_property dp  ON dp.property_key  = fa.property_key
JOIN gold.dm_person   dpe ON dpe.person_key   = fa.person_key
JOIN gold.dm_date     dd  ON dd.date_key      = fa.date_key;

CREATE OR REPLACE VIEW dw.vw_ft_user_goal AS
WITH consumption_per_person AS (
    SELECT
          up.user_id
        , AVG(cd.total_liters) AS avg_liters_last_30d
    FROM tb_user_property up
    JOIN gold.dm_property          gp ON gp.property_id   = up.property_id
    JOIN gold.ft_consumption_daily cd ON cd.property_key  = gp.property_key
    JOIN gold.dm_date              dd ON dd.date_key      = cd.date_key
    WHERE dd.full_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY up.user_id
)
SELECT
      dpe.user_id
    , dpe.name
    , pr.daily_liters_target
    , COALESCE(c.avg_liters_last_30d, 0) AS avg_liters_last_30d
    , ROUND(COALESCE(c.avg_liters_last_30d, 0) / NULLIF(pr.daily_liters_target, 0) * 100, 1) AS pct_of_target
FROM gold.dm_user_preference pr
JOIN gold.dm_person dpe ON dpe.person_key = pr.person_key
LEFT JOIN consumption_per_person c ON c.user_id = dpe.user_id;

GRANT USAGE ON SCHEMA stage, silver, gold, dw TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO sys_data_engineer;

GRANT USAGE ON SCHEMA gold, dw TO sys_bi_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA gold, dw TO sys_bi_analyst;

CREATE INDEX IF NOT EXISTS idx_log_region_rate_previous_log_id
    ON tb_log_region_rate (previous_log_id);

COMMIT;
