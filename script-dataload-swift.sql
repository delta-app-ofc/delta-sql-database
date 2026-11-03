-- ============================================================
-- SCRIPT DE DADOS DA ORGANIZACAO SWIFT (referencia: prototipo delta.html)
-- ============================================================
-- Completa a organizacao SWIFT DISTRIBUIDORA (id=1) com as 10 unidades do
-- prototipo, metas mensais, dispositivos, ~3 meses de consumo, status dos
-- dispositivos e alertas, e executa o ETL (stage -> silver -> gold).
--
-- Pre-requisitos: script-schema, script-dataload e script-datamart ja rodados.
-- Idempotente: pode ser re-executado sem erros nem duplicar linhas.
-- Os dados de stage simulam o que o bi_etl.py traria do Mongo; em producao
-- o ETL real alimenta as mesmas tabelas.
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_org_id        INTEGER;
    v_user_id       INTEGER := 2;   -- gestor da organizacao (tb_user_organization)
    v_class_id      INTEGER;        -- classificacao comercial das lojas ja existentes
    v_start         DATE := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 months')::DATE;
    v_end           DATE := CURRENT_DATE - 1;
    r               RECORD;
    v_region_id     INTEGER;
    v_addr_id       INTEGER;
    v_prop_id       INTEGER;
BEGIN

    SELECT id INTO v_org_id FROM tb_organization WHERE cnpj = '12345678000190';
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'Organizacao SWIFT nao encontrada: rode script-dataload.sql antes.';
    END IF;
    SELECT classification_id INTO v_class_id FROM tb_property WHERE name = 'LOJA SWIFT - VILA LEOPOLDINA';

    CREATE TEMP TABLE seed_store (
          prop_name   VARCHAR(100)
        , region_name VARCHAR(30)
        , cep         CHAR(8)
        , city        VARCHAR(60)
        , latitude    NUMERIC(8,6)
        , longitude   NUMERIC(9,6)
        , area_m2     NUMERIC(10,2)
        , month_liters NUMERIC(12,2)  -- consumo do ultimo mes completo (litros)
        , goal_pct    NUMERIC(5,1)    -- % da meta consumida no ultimo mes
        , reduction_pct NUMERIC(5,1)  -- reducao vs mes anterior (negativo = aumento)
        , device_id   VARCHAR(100)
        , is_online   BOOLEAN
        , battery     SMALLINT
        , ping_min    INTEGER         -- minutos desde o ultimo ping
    ) ON COMMIT DROP;

    INSERT INTO seed_store VALUES
    ('LOJA SWIFT - VILA LEOPOLDINA', 'GRANDE_SP', NULL,       'São Paulo',               -23.550000, -46.650000,  850,  4680, 78,  12, 'ESP32-SP-1000', TRUE,  82,   3),
    ('LOJA SWIFT - VILA ROMANA',     'GRANDE_SP', NULL,       'São Paulo',               -23.570000, -46.670000, 1200,  8420, 91, -16, 'ESP32-SP-1001', TRUE,  15,   8),
    ('LOJA SWIFT - PERDIZES',        'GRANDE_SP', NULL,       'São Paulo',               -23.560000, -46.640000,  950,  6150, 64,   8, 'ESP32-SP-0153', TRUE,  64,   1),
    ('LOJA SWIFT - PINHEIROS',       'GRANDE_SP', '05422000', 'São Paulo',               -23.560000, -46.680000, 1800, 12300,112, -31, 'ESP32-SP-1002', FALSE, 41, 360),
    ('LOJA SWIFT - MOEMA',           'GRANDE_SP', '04077000', 'São Paulo',               -23.580000, -46.620000,  650,  3920, 52,  18, 'ESP32-SP-1003', TRUE,  93,   2),
    ('LOJA SWIFT - TATUAPE',         'GRANDE_SP', '03067000', 'São Paulo',               -23.540000, -46.580000,  780,  5340, 69,   6, 'ESP32-SP-1004', TRUE,  88,   6),
    ('CENTRO DE DISTRIBUICAO SWIFT - CAMPINAS', 'INTERIOR', '13015000', 'Campinas',      -22.900000, -47.060000, 3200, 15680,118, -24, 'ESP32-SP-1005', TRUE,  58,  12),
    ('LOJA SWIFT - SOROCABA',        'INTERIOR',  '18035000', 'Sorocaba',                -23.500000, -47.450000, 1100,  7210, 88,  -9, 'ESP32-SP-1006', TRUE,  76,   5),
    ('LOJA SWIFT - SANTOS',          'LITORAL',   '11010000', 'Santos',                  -23.960000, -46.330000,  900,  5890, 71,  14, 'ESP32-SP-1007', TRUE,  71,   4),
    ('LOJA SWIFT - SAO JOSE DOS CAMPOS', 'VALE_DO_PARAIBA', '12210000', 'São José dos Campos', -23.180000, -45.880000, 1350, 9450, 95, -11, 'ESP32-SP-1008', TRUE, 8, 25);

    -- ----------------------------------------------------------
    -- 1. ENDERECOS E PROPRIEDADES (as 3 primeiras lojas ja existem)
    -- ----------------------------------------------------------
    FOR r IN SELECT * FROM seed_store LOOP
        SELECT id INTO v_prop_id FROM tb_property WHERE name = r.prop_name;

        IF v_prop_id IS NULL THEN
            SELECT id INTO v_region_id FROM tb_region WHERE name = r.region_name;
            INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
            SELECT v_region_id, r.cep, r.city, 'SP', r.latitude, r.longitude
            WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = r.cep);
            SELECT id INTO v_addr_id FROM tb_address WHERE cep = r.cep;

            INSERT INTO tb_property (name, type, classification_id, address_id, organization_id, built_area_m2, registration_date)
            VALUES (r.prop_name, 'PRÉDIO', v_class_id, v_addr_id, v_org_id, r.area_m2, CURRENT_DATE - 120)
            ON CONFLICT (name, address_id) DO NOTHING;
            SELECT id INTO v_prop_id FROM tb_property WHERE name = r.prop_name;
        ELSE
            UPDATE tb_address SET latitude = r.latitude, longitude = r.longitude
             WHERE id = (SELECT address_id FROM tb_property WHERE id = v_prop_id);
        END IF;

        INSERT INTO tb_user_property (user_id, property_id) VALUES (v_user_id, v_prop_id)
        ON CONFLICT (user_id, property_id) DO NOTHING;

        INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
        VALUES (r.device_id, v_prop_id, TRUE, CURRENT_DATE - 100)
        ON CONFLICT (device_id) DO NOTHING;

        -- meta mensal = consumo do ultimo mes / (% da meta consumida)
        INSERT INTO tb_property_goal (property_id, monthly_target_liters)
        VALUES (v_prop_id, ROUND(r.month_liters * 100 / r.goal_pct, 2))
        ON CONFLICT (property_id) DO UPDATE SET monthly_target_liters = EXCLUDED.monthly_target_liters;
    END LOOP;

    UPDATE tb_organization SET declared_unit_count = 10 WHERE id = v_org_id;

    -- ----------------------------------------------------------
    -- 2. CONSUMO (stage.consumption_summary): janelas de 60 min no historico
    --    e de 10 min nos ultimos 3 dias. Mes mais recente = month_liters;
    --    mes anterior = month_liters / (1 - reducao%); antes dele, -3%.
    -- ----------------------------------------------------------
    INSERT INTO stage.consumption_summary
        (mongo_id, device_id, user_id, window_started_at, window_finished_at, consumption_liters, lpm_average, anomaly_detected)
    WITH windows AS (
        SELECT
              s.device_id
            , w.started_at
            , w.minutes
            , s.month_liters
            , s.reduction_pct
            , DATE_TRUNC('month', w.started_at) AS month_start
        FROM seed_store s
        CROSS JOIN LATERAL (
            SELECT g AS started_at, 60 AS minutes
              FROM generate_series(v_start::TIMESTAMP, (v_end - 3)::TIMESTAMP + INTERVAL '23 hours', INTERVAL '1 hour') g
            UNION ALL
            SELECT g, 10
              FROM generate_series((v_end - 2)::TIMESTAMP, v_end::TIMESTAMP + INTERVAL '23 hours 50 minutes', INTERVAL '10 minutes') g
        ) w
    ),
    shaped AS (
        SELECT
              wi.*
            , (wi.month_liters
                 * CASE
                       WHEN wi.month_start = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') THEN 1.0
                       WHEN wi.month_start = DATE_TRUNC('month', CURRENT_DATE) THEN 1.0
                       WHEN wi.month_start = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 months')
                            THEN 1.0 / GREATEST(1 - wi.reduction_pct / 100.0, 0.5)
                       ELSE 1.0
                   END
              ) / EXTRACT(DAY FROM (wi.month_start + INTERVAL '1 month' - INTERVAL '1 day'))          AS daily_liters
            , CASE WHEN EXTRACT(HOUR FROM wi.started_at) BETWEEN 8 AND 19
                   THEN 1.0 + 0.4 * SIN(EXTRACT(HOUR FROM wi.started_at) / 2.0)
                   ELSE 0.15 END                                                                     AS hour_weight
        FROM windows wi
    ),
    weighted AS (
        SELECT
              sh.*
            , sh.hour_weight / SUM(sh.hour_weight * (sh.minutes / 60.0))
                  OVER (PARTITION BY sh.device_id, DATE(sh.started_at)) AS day_share
        FROM shaped sh
    )
    SELECT
          SUBSTR(MD5('swift' || w.device_id || w.started_at::TEXT), 1, 24)
        , w.device_id
        , v_user_id::TEXT
        , w.started_at
        , w.started_at + (w.minutes || ' minutes')::INTERVAL
        , ROUND((w.daily_liters * w.day_share * (w.minutes / 60.0)
                  * (0.9 + 0.2 * ABS(SIN(EXTRACT(EPOCH FROM w.started_at) / 5000.0))))::NUMERIC, 3)
        , ROUND((w.daily_liters * w.day_share / 60.0
                  * (0.9 + 0.2 * ABS(SIN(EXTRACT(EPOCH FROM w.started_at) / 5000.0))))::NUMERIC, 3)
        , FALSE
    FROM weighted w
    ON CONFLICT (mongo_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 3. STATUS DOS DISPOSITIVOS (stage.device_status)
    -- ----------------------------------------------------------
    INSERT INTO stage.device_status
        (mongo_id, device_id, last_ping_at, wifi_signal_rssi, firmware_version, connectivity_status, battery_level, unavailability_reason)
    SELECT
          SUBSTR(MD5('status' || s.device_id), 1, 24)
        , s.device_id
        , CURRENT_TIMESTAMP - (s.ping_min || ' minutes')::INTERVAL
        , '-' || (55 + (ABS(HASHTEXT(s.device_id)) % 20))::TEXT
        , '1.4.2'
        , CASE WHEN s.is_online THEN 'online' ELSE 'offline' END
        , s.battery
        , CASE WHEN s.is_online THEN NULL ELSE 'SEM_COMUNICACAO' END
    FROM seed_store s
    ON CONFLICT (mongo_id) DO UPDATE
        SET last_ping_at          = EXCLUDED.last_ping_at
          , connectivity_status   = EXCLUDED.connectivity_status
          , battery_level         = EXCLUDED.battery_level
          , unavailability_reason = EXCLUDED.unavailability_reason;

    -- ----------------------------------------------------------
    -- 4. ALERTAS (stage.alerts_history)
    --    severity: high = critico, medium = atencao, low = informativo
    -- ----------------------------------------------------------
    INSERT INTO stage.alerts_history (mongo_id, device_id, user_id, alert_type, triggered_at, resolved_at, severity)
    VALUES
    -- vazamento ativo (Pinheiros): fluxo continuo desde ontem a noite
    (SUBSTR(MD5('alert-pinheiros-ativo'), 1, 24), 'ESP32-SP-1002', v_user_id, 'vazamento_continuo',
        (CURRENT_DATE - 1) + TIME '21:40', NULL, 'high'),
    -- vazamento ativo em investigacao (Sao Jose dos Campos)
    (SUBSTR(MD5('alert-sjc-ativo'), 1, 24), 'ESP32-SP-1008', v_user_id, 'vazamento_continuo',
        (CURRENT_DATE - 1) + TIME '03:10', NULL, 'medium'),
    -- vazamentos resolvidos (historico)
    (SUBSTR(MD5('alert-romana-resolvido'), 1, 24), 'ESP32-SP-1001', v_user_id, 'vazamento_continuo',
        (CURRENT_DATE - 36) + TIME '10:00', (CURRENT_DATE - 36) + TIME '12:10', 'medium'),
    (SUBSTR(MD5('alert-moema-resolvido'), 1, 24), 'ESP32-SP-1003', v_user_id, 'vazamento_continuo',
        (CURRENT_DATE - 50) + TIME '14:00', (CURRENT_DATE - 50) + TIME '14:40', 'low'),
    -- consumo acima do esperado / padrao anormal
    (SUBSTR(MD5('alert-romana-fluxo'), 1, 24), 'ESP32-SP-1001', v_user_id, 'fluxo_atipico',
        (CURRENT_DATE - 1) + TIME '18:00', NULL, 'medium'),
    (SUBSTR(MD5('alert-perdizes-fluxo'), 1, 24), 'ESP32-SP-0153', v_user_id, 'fluxo_atipico',
        (CURRENT_DATE - 1) + TIME '22:30', NULL, 'medium'),
    (SUBSTR(MD5('alert-campinas-fluxo'), 1, 24), 'ESP32-SP-1005', v_user_id, 'fluxo_atipico',
        (CURRENT_DATE - 2) + TIME '15:20', NULL, 'high'),
    -- dispositivo offline
    (SUBSTR(MD5('alert-pinheiros-offline'), 1, 24), 'ESP32-SP-1002', v_user_id, 'dispositivo_offline',
        CURRENT_TIMESTAMP - INTERVAL '6 hours', NULL, 'medium'),
    (SUBSTR(MD5('alert-sjc-bateria'), 1, 24), 'ESP32-SP-1008', v_user_id, 'leitura_impossivel',
        (CURRENT_DATE - 1) + TIME '08:00', (CURRENT_DATE - 1) + TIME '09:00', 'low')
    ON CONFLICT (mongo_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 5. CENARIOS DE INVESTIMENTO (CAPEX) da organizacao
    -- ----------------------------------------------------------
    INSERT INTO tb_investment_scenario (organization_id, name, investment_value, reduction_pct, annual_savings_value, payback_months, description)
    SELECT v_org_id, c.name, c.investment, c.reduction, c.savings, c.payback, c.descr
    FROM (VALUES
        ('TORNEIRAS ECONOMICAS', 18000.00, 12.0, 22200.00,  9.7, 'Troca de torneiras e valvulas por modelos de fechamento automatico e baixo fluxo.'),
        ('REUSO DE AGUA',        75000.00, 28.0, 51800.00, 17.3, 'Estacao de tratamento e reaproveitamento de agua cinza para limpeza e descarga.'),
        ('CAPTACAO DE CHUVA',    42000.00, 19.0, 35400.00, 14.2, 'Captacao e reservacao de agua de chuva para uso nao potavel.')
    ) AS c(name, investment, reduction, savings, payback, descr)
    WHERE NOT EXISTS (
        SELECT 1 FROM tb_investment_scenario x WHERE x.organization_id = v_org_id AND x.name = c.name
    );

END;
$$;

COMMIT;

-- ETL: stage -> silver -> gold (as views dw leem apenas gold)
CALL silver.sp_load();
CALL gold.sp_load();
