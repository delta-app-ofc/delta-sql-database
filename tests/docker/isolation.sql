BEGIN;
SET LOCAL session_replication_role = replica;

CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE TABLE dw.vw_ft_consumption_daily (property_id INTEGER, full_date DATE, total_liters NUMERIC, cost_value NUMERIC);
CREATE TABLE gold.dm_property (property_key INTEGER, property_id INTEGER);
CREATE TABLE gold.ft_consumption_daily (property_key INTEGER);

INSERT INTO tb_property (id, organization_id, address_id, classification_id, name, type)
VALUES (100, 1, 1, 1, 'FILIAL A', 'CASA'), (200, 2, 1, 1, 'FILIAL B', 'CASA');
INSERT INTO tb_address (id, region_id, cep, city, state) VALUES (1, 1, '01001000', 'SAO PAULO', 'SP');
INSERT INTO tb_user_organization (user_id, organization_id) VALUES (10, 1), (20, 2);

INSERT INTO dw.vw_ft_consumption_daily VALUES
  (100, DATE '2026-10-29', 1000, 10), (200, DATE '2026-10-29', 5000, 50);
INSERT INTO gold.dm_property VALUES (1, 100), (2, 200);
INSERT INTO gold.ft_consumption_daily VALUES (1);

DO $$
DECLARE
    v_total NUMERIC;
BEGIN
    IF fn_user_authorized_property_ids(10, ARRAY[100, 200]) <> ARRAY[100] THEN
        RAISE EXCEPTION 'helper devolveu propriedade de outra organizacao';
    END IF;
    IF fn_user_authorized_property_ids(99, ARRAY[100, 200]) <> ARRAY[]::INTEGER[] THEN
        RAISE EXCEPTION 'usuario sem organizacao nao deveria ter propriedades';
    END IF;

    SELECT SUM(total_liters) INTO v_total
      FROM fn_organization_consumption_history(10, ARRAY[100, 200], 30, DATE '2026-10-30');
    IF v_total IS DISTINCT FROM 1000 THEN
        RAISE EXCEPTION 'history misturou organizacoes: %', v_total;
    END IF;
    IF EXISTS (SELECT 1 FROM fn_organization_consumption_history(10, ARRAY[200], 30, DATE '2026-10-30')) THEN
        RAISE EXCEPTION 'history devolveu dados de propriedade alheia';
    END IF;

    IF NOT fn_organization_can_estimate(10, ARRAY[100]) THEN
        RAISE EXCEPTION 'can_estimate deveria ser true para a propria propriedade';
    END IF;
    IF fn_organization_can_estimate(10, ARRAY[200]) THEN
        RAISE EXCEPTION 'can_estimate aceitou propriedade alheia';
    END IF;

    IF fn_organization_effective_rate(10, ARRAY[200], DATE '2026-10-30', 30) IS NOT NULL THEN
        RAISE EXCEPTION 'effective_rate usou propriedade alheia';
    END IF;
    IF fn_organization_effective_rate(10, ARRAY[100, 200], DATE '2026-10-30', 30) IS DISTINCT FROM 10.0 THEN
        RAISE EXCEPTION 'effective_rate propria incorreta';
    END IF;

    IF EXISTS (SELECT 1 FROM fn_organization_last_billed_period(10, ARRAY[200], DATE '2026-10-30')) THEN
        RAISE EXCEPTION 'last_billed_period devolveu dados de propriedade alheia';
    END IF;
    SELECT total_liters INTO v_total
      FROM fn_organization_last_billed_period(10, ARRAY[100, 200], DATE '2026-10-30');
    IF v_total IS DISTINCT FROM 1000 THEN
        RAISE EXCEPTION 'last_billed_period misturou organizacoes: %', v_total;
    END IF;

    IF (SELECT can_estimate FROM fn_organization_forecast_context(10, NULL, DATE '2026-10-30')) IS NOT TRUE THEN
        RAISE EXCEPTION 'forecast_context nao encontrou dados da propria organizacao';
    END IF;
END
$$;

SELECT 'isolation checks passed' AS result;
ROLLBACK;
