-- ============================================================
-- SCRIPT DE DADOS PARA O USUÁRIO JOTA (id=204, jota@delta.com)
-- ============================================================
-- Popula o usuário jota com 2 propriedades (residencial e social),
-- dispositivos, consumo na stage e ETL para Silver/Gold.
--
-- Busca os ids dos catálogos via SELECT antes de inserir.
-- Idempotente: pode ser re-executado sem erros.
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_class_res_id  INTEGER;  -- RESIDENCIAL_NORMAL
    v_class_soc_id  INTEGER;  -- RESIDENCIAL_SOCIAL
    v_region_sp_id  INTEGER;  -- GRANDE_SP
    v_region_ln_id  INTEGER;  -- LINS
    v_dow_seg       INTEGER;
    v_dow_qua       INTEGER;
    v_dow_sex       INTEGER;

    v_addr_res_id   INTEGER;
    v_addr_soc_id   INTEGER;
    v_prop_res_id   INTEGER;
    v_prop_soc_id   INTEGER;
    v_user_id       INTEGER := 204;
BEGIN

    -- ----------------------------------------------------------
    -- 0. BUSCA IDS DOS CATÁLOGOS
    -- ----------------------------------------------------------
    SELECT id INTO v_class_res_id FROM tb_property_classification WHERE name = 'RESIDENCIAL_NORMAL';
    SELECT id INTO v_class_soc_id FROM tb_property_classification WHERE name = 'RESIDENCIAL_SOCIAL';

    SELECT id INTO v_region_sp_id FROM tb_region WHERE name = 'GRANDE_SP';
    SELECT id INTO v_region_ln_id FROM tb_region WHERE name = 'LINS';

    SELECT id INTO v_dow_seg FROM tb_day_of_week WHERE name = 'SEGUNDA';
    SELECT id INTO v_dow_qua FROM tb_day_of_week WHERE name = 'QUARTA';
    SELECT id INTO v_dow_sex FROM tb_day_of_week WHERE name = 'SEXTA';

    -- ----------------------------------------------------------
    -- 1. ENDEREÇOS
    -- tb_address não tem UNIQUE — usa WHERE NOT EXISTS
    -- ----------------------------------------------------------
    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT v_region_sp_id, '04038001', 'São Paulo', 'SP', -23.6101, -46.6648
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '04038001');
    SELECT id INTO v_addr_res_id FROM tb_address WHERE cep = '04038001';

    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT v_region_ln_id, '16900010', 'Lins', 'SP', -21.6800, -49.7450
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '16900010');
    SELECT id INTO v_addr_soc_id FROM tb_address WHERE cep = '16900010';

    -- ----------------------------------------------------------
    -- 2. PROPRIEDADES
    -- ----------------------------------------------------------
    INSERT INTO tb_property (name, type, classification_id, address_id, built_area_m2, registration_date)
    VALUES ('CASA JOTA RESIDENCIAL', 'CASA', v_class_res_id, v_addr_res_id, 110.00, '2023-02-01')
    ON CONFLICT (name, address_id) DO NOTHING;
    SELECT id INTO v_prop_res_id FROM tb_property WHERE name = 'CASA JOTA RESIDENCIAL' AND address_id = v_addr_res_id;

    INSERT INTO tb_property (name, type, classification_id, address_id, built_area_m2, registration_date)
    VALUES ('CASA JOTA SOCIAL', 'CASA', v_class_soc_id, v_addr_soc_id, 75.00, '2023-03-15')
    ON CONFLICT (name, address_id) DO NOTHING;
    SELECT id INTO v_prop_soc_id FROM tb_property WHERE name = 'CASA JOTA SOCIAL' AND address_id = v_addr_soc_id;

    RAISE NOTICE 'Propriedades jota: residencial=%, social=%', v_prop_res_id, v_prop_soc_id;

    -- ----------------------------------------------------------
    -- 3. VÍNCULOS USUÁRIO ↔ PROPRIEDADES
    -- ----------------------------------------------------------
    INSERT INTO tb_user_property (user_id, property_id) VALUES (v_user_id, v_prop_res_id) ON CONFLICT (user_id, property_id) DO NOTHING;
    INSERT INTO tb_user_property (user_id, property_id) VALUES (v_user_id, v_prop_soc_id) ON CONFLICT (user_id, property_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 4. DISPOSITIVOS
    -- ----------------------------------------------------------
    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    VALUES ('ESP32-SP-JOTA-01', v_prop_res_id, TRUE, '2023-02-05')
    ON CONFLICT (device_id) DO NOTHING;

    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    VALUES ('ESP32-SP-JOTA-03', v_prop_soc_id, TRUE, '2023-03-20')
    ON CONFLICT (device_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 5. FATURAS DE ÁGUA (3 meses)
    -- ----------------------------------------------------------
    INSERT INTO tb_last_water_bill (user_id, month, total_value, m3_value) VALUES (v_user_id, '2026-08-01', 68.40, 9.50)  ON CONFLICT (user_id, month) DO NOTHING;
    INSERT INTO tb_last_water_bill (user_id, month, total_value, m3_value) VALUES (v_user_id, '2026-09-01', 74.90, 10.40) ON CONFLICT (user_id, month) DO NOTHING;
    INSERT INTO tb_last_water_bill (user_id, month, total_value, m3_value) VALUES (v_user_id, '2026-10-01', 82.10, 11.40) ON CONFLICT (user_id, month) DO NOTHING;

    -- ----------------------------------------------------------
    -- 6. PERFIL OPERACIONAL (social usa cisterna)
    -- ----------------------------------------------------------
    INSERT INTO tb_property_operational_profile (property_id, main_water_source)
    VALUES (v_prop_soc_id, 'POCO_ARTESIANO')
    ON CONFLICT (property_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 7. DIAS DE OPERAÇÃO (social: segunda, quarta, sexta)
    -- ----------------------------------------------------------
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_soc_id, v_dow_seg) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_soc_id, v_dow_qua) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_soc_id, v_dow_sex) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;

END;
$$;


-- ============================================================
-- CONSUMO NA STAGE (3 meses × 2 propriedades)
-- ============================================================
INSERT INTO stage.consumption_summary (
    mongo_id, device_id, user_id,
    window_started_at, window_finished_at,
    consumption_liters, lpm_average, anomaly_detected
)
SELECT
    RPAD(props.prefix || TO_CHAR(d, 'YYYYMMDD') || props.sfx, 13),
    props.device_id,
    '204',
    d + props.t_start,
    d + props.t_end,
    props.liters,
    ROUND((props.liters / 360.0)::NUMERIC, 3),
    FALSE
FROM
    generate_series('2026-08-01'::date, '2026-10-31'::date, '1 day') AS d,
    (VALUES
        ('jt01', 'ESP32-SP-JOTA-01', 'a', TIME '06:00', TIME '12:00',  75.0),
        ('jt01', 'ESP32-SP-JOTA-01', 'b', TIME '12:00', TIME '18:00',  95.0),
        ('jt03', 'ESP32-SP-JOTA-03', 'a', TIME '06:00', TIME '12:00',  40.0),
        ('jt03', 'ESP32-SP-JOTA-03', 'b', TIME '12:00', TIME '18:00',  55.0)
    ) AS props(prefix, device_id, sfx, t_start, t_end, liters)
ORDER BY d, props.prefix, props.sfx
ON CONFLICT (mongo_id) DO NOTHING;

-- Anomalias
UPDATE stage.consumption_summary SET consumption_liters = 260.0, lpm_average = 0.722, anomaly_detected = TRUE
WHERE TRIM(mongo_id) = 'jt0120260812b';

UPDATE stage.consumption_summary SET consumption_liters = 160.0, lpm_average = 0.444, anomaly_detected = TRUE
WHERE TRIM(mongo_id) = 'jt0320261018b';


-- ============================================================
-- STAGE: dados que o bi_etl.py traria do db_delta_app (Mongo)
-- ============================================================
-- Meta diária e preferências do usuário (user_preferences)
INSERT INTO stage.user_preferences (
    mongo_id, user_id, daily_liters_target, notifications_enabled,
    quiet_start_hour, quiet_end_hour, dark_mode_enabled
)
SELECT RPAD('jtpref204', 24), 204, 300, TRUE, '22:00', '07:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM stage.user_preferences WHERE user_id = 204);

-- Histórico de alertas (alerts_history): um resolvido e um ainda ativo
INSERT INTO stage.alerts_history (mongo_id, device_id, user_id, alert_type, triggered_at, resolved_at, severity)
SELECT RPAD('jtalert01', 24), 'ESP32-SP-JOTA-01', 204, 'fluxo_atipico',
       TIMESTAMP '2026-08-12 14:10', TIMESTAMP '2026-08-12 15:00', 'medium'
WHERE NOT EXISTS (SELECT 1 FROM stage.alerts_history WHERE mongo_id = RPAD('jtalert01', 24));

INSERT INTO stage.alerts_history (mongo_id, device_id, user_id, alert_type, triggered_at, resolved_at, severity)
SELECT RPAD('jtalert02', 24), 'ESP32-SP-JOTA-03', 204, 'vazamento_continuo',
       TIMESTAMP '2026-10-18 13:30', NULL, 'high'
WHERE NOT EXISTS (SELECT 1 FROM stage.alerts_history WHERE mongo_id = RPAD('jtalert02', 24));


-- ============================================================
-- ETL: Silver e Gold
-- ============================================================
CALL silver.sp_load();
CALL gold.sp_load();

COMMIT;
