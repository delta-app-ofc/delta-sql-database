BEGIN;
SET LOCAL session_replication_role = replica;

CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE TABLE dw.vw_ft_consumption_daily (
    property_id INTEGER,
    full_date DATE,
    total_liters NUMERIC,
    cost_value NUMERIC
);
CREATE TABLE gold.dm_property (property_key INTEGER, property_id INTEGER);
CREATE TABLE gold.ft_consumption_daily (property_key INTEGER);

INSERT INTO tb_region (id, name) VALUES (1, 'GRANDE_SP');
INSERT INTO tb_property_classification (id, name, group_name)
VALUES (1, 'COMERCIAL_NORMAL_INDUSTRIAL', 'COMERCIAL');
INSERT INTO tb_organization (id, corporate_name, trade_name, cnpj, business_segment)
VALUES
    (1, 'ORGANIZACAO UM SA', 'ORG UM', '00000000000001', 'VAREJO'),
    (2, 'ORGANIZACAO DOIS SA', 'ORG DOIS', '00000000000002', 'VAREJO');
INSERT INTO tb_user (id, name, email, password, birth_date)
VALUES
    (10, 'USUARIO UM', 'usuario.um@example.test', 'placeholder', DATE '1990-01-01'),
    (20, 'USUARIO DOIS', 'usuario.dois@example.test', 'placeholder', DATE '1990-01-01');
INSERT INTO tb_address (id, region_id, cep, city, state)
VALUES
    (1, 1, '01001000', 'SAO PAULO', 'SP'),
    (2, 1, '02002000', 'SAO PAULO', 'SP'),
    (3, 1, '03003000', 'SAO PAULO', 'SP');
INSERT INTO tb_property (id, organization_id, address_id, classification_id, name, type)
VALUES
    (100, 1, 1, 1, 'FILIAL A', 'CASA'),
    (101, 1, 2, 1, 'FILIAL A SUL', 'CASA'),
    (102, 1, 3, 1, 'FILIAL A NORTE', 'CASA'),
    (200, 2, 1, 1, 'FILIAL B', 'CASA');
INSERT INTO tb_user_organization (user_id, organization_id)
VALUES (10, 1), (20, 2);

INSERT INTO dw.vw_ft_consumption_daily VALUES
    (100, DATE '2026-09-05', 400, 4),
    (100, DATE '2026-09-30', 600, 6),
    (100, DATE '2026-10-01', 2000, 20),
    (100, DATE '2026-10-29', 1000, 10),
    (100, DATE '2026-10-30', 100, 1),
    (200, DATE '2026-10-29', 5000, 50);
INSERT INTO gold.dm_property VALUES (1, 100), (2, 200);
INSERT INTO gold.ft_consumption_daily VALUES (1), (2);

DO $$
DECLARE
    v_total NUMERIC;
    v_context RECORD;
    v_reference_month DATE;
    v_last_bill_liters NUMERIC;
    v_last_bill_cost NUMERIC;
BEGIN
    IF fn_user_authorized_property_ids(10, ARRAY[100, 200]) IS DISTINCT FROM ARRAY[100] THEN
        RAISE EXCEPTION 'property authorization included another organization';
    END IF;
    IF fn_user_authorized_property_ids(99, ARRAY[100, 200]) IS DISTINCT FROM ARRAY[]::INTEGER[] THEN
        RAISE EXCEPTION 'user without an organization should have no authorized properties';
    END IF;

    SELECT SUM(total_liters) INTO v_total
      FROM fn_organization_consumption_history(10, ARRAY[100, 200], 30, DATE '2026-10-30');
    IF v_total IS DISTINCT FROM 3100 THEN
        RAISE EXCEPTION 'history should include the 30-day inclusive window, got %', v_total;
    END IF;
    IF EXISTS (
        SELECT 1 FROM fn_organization_consumption_history(10, ARRAY[200], 30, DATE '2026-10-30')
    ) THEN
        RAISE EXCEPTION 'history returned data for another organization';
    END IF;

    IF fn_organization_can_estimate(10, ARRAY[100]) IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'can_estimate should be true for the user''s own property';
    END IF;
    IF fn_organization_can_estimate(10, ARRAY[200]) IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION 'can_estimate accepted another organization''s property';
    END IF;

    IF fn_organization_effective_rate(10, ARRAY[200], DATE '2026-10-30', 30) IS NOT NULL THEN
        RAISE EXCEPTION 'effective_rate used another organization''s property';
    END IF;
    IF fn_organization_effective_rate(10, ARRAY[100, 200], DATE '2026-10-30', 30) IS DISTINCT FROM 10.0 THEN
        RAISE EXCEPTION 'effective_rate should use only the authorized 30-day data';
    END IF;

    SELECT reference_month, total_liters, total_cost
      INTO v_reference_month, v_last_bill_liters, v_last_bill_cost
      FROM fn_organization_last_billed_period(10, ARRAY[100, 200], DATE '2026-10-30');
    IF v_reference_month IS DISTINCT FROM DATE '2026-09-01'
       OR v_last_bill_liters IS DISTINCT FROM 1000
       OR v_last_bill_cost IS DISTINCT FROM 10 THEN
        RAISE EXCEPTION 'last billed period should aggregate the previous closed month';
    END IF;
    IF EXISTS (
        SELECT 1 FROM fn_organization_last_billed_period(10, ARRAY[200], DATE '2026-10-30')
    ) THEN
        RAISE EXCEPTION 'last_billed_period returned data for another organization';
    END IF;

    SELECT reference_month, total_liters
      INTO v_reference_month, v_last_bill_liters
      FROM fn_organization_last_billed_period(20, ARRAY[200], DATE '2026-10-30');
    IF v_reference_month IS DISTINCT FROM DATE '2026-10-01' OR v_last_bill_liters IS DISTINCT FROM 5000 THEN
        RAISE EXCEPTION 'last_billed_period fallback should select the latest available month';
    END IF;

    SELECT * INTO v_context
      FROM fn_organization_forecast_context(10, NULL, DATE '2026-10-30', 45, 30);
    IF v_context.access_kind IS DISTINCT FROM 'organizational'
       OR v_context.match_status IS DISTINCT FROM 'resolved'
       OR v_context.resolved_property_ids IS NULL
       OR NOT (100 = ANY(v_context.resolved_property_ids))
       OR v_context.can_estimate IS NOT TRUE THEN
        RAISE EXCEPTION 'forecast_context did not resolve the user''s organization';
    END IF;
    IF v_context.last_bill_month IS DISTINCT FROM DATE '2026-09-01'
       OR v_context.last_bill_total_value IS DISTINCT FROM 10
       OR v_context.last_bill_m3_value IS DISTINCT FROM 1
       OR v_context.effective_rate IS DISTINCT FROM 10 THEN
        RAISE EXCEPTION 'forecast_context returned incorrect billing and rate values';
    END IF;
    IF v_context.history IS NULL OR json_array_length(v_context.history) <> 4 THEN
        RAISE EXCEPTION 'forecast_context should include the four readings in its history window';
    END IF;

    SELECT * INTO v_context
      FROM fn_organization_forecast_context(10, 'FILIAL A', DATE '2026-10-30');
    IF v_context.match_status IS DISTINCT FROM 'ambiguous'
       OR v_context.resolved_property_ids IS NOT NULL
       OR json_array_length(v_context.candidate_properties) <> 3
       OR v_context.can_estimate IS NOT FALSE THEN
        RAISE EXCEPTION 'forecast_context should report ambiguous organization matches';
    END IF;

    SELECT * INTO v_context
      FROM fn_organization_forecast_context(10, 'INEXISTENTE', DATE '2026-10-30');
    IF v_context.match_status IS DISTINCT FROM 'not_found'
       OR json_array_length(v_context.candidate_properties) <> 3
       OR v_context.candidate_properties::TEXT LIKE '%FILIAL B%' THEN
        RAISE EXCEPTION 'not_found candidates should stay inside the user''s organization';
    END IF;

    SELECT * INTO v_context
      FROM fn_organization_forecast_context(99, NULL, DATE '2026-10-30');
    IF v_context.access_kind IS DISTINCT FROM 'none'
       OR v_context.match_status IS DISTINCT FROM 'not_applicable'
       OR v_context.can_estimate IS NOT FALSE
       OR v_context.resolved_property_ids IS NOT NULL THEN
        RAISE EXCEPTION 'forecast_context should deny a user without organization access';
    END IF;
END
$$;

SELECT 'organization behavior checks passed' AS result;
ROLLBACK;
