-- ============================================================
-- SCRIPT DE DADOS PARA A FEIRA
-- ============================================================
-- Cria um usuário completo para demonstração na feira, com 3
-- propriedades e todos os casos possíveis das tabelas do banco.
-- Ao final, chama os procedimentos ETL para popular as camadas
-- Silver e Gold automaticamente.
--
-- Pré-requisito: executar após script-dataload.sql.
-- Não interfere com os usuários 1-200 nem com o usuário 210.
--
-- TABELAS PÚBLICAS COBERTAS
-- tb_user, tb_address, tb_property, tb_user_property
-- tb_organization, tb_user_organization
-- tb_device, tb_last_water_bill
-- tb_property_operational_profile, tb_property_shift
-- tb_property_water_usage, tb_property_operation_day
-- tb_user_habit, tb_user_habit_day
--
-- CASOS DE tb_user_habit MAPEADOS
-- [A] Com horário + com estimativa de litros  → BANHO LONGO, REGAR PLANTAS, LAVAR ROUPA
-- [B] Com horário + sem estimativa de litros  → LAVAR LOUÇA
-- [C] Sem horário + com estimativa de litros  → LAVAR CARRO
-- [D] Sem horário + sem estimativa de litros  → LAVAR QUINTAL
-- [E] frequency = 1 (uma vez)                → BANHO LONGO, LAVAR CARRO
-- [F] frequency = 2                          → LAVAR QUINTAL
-- [G] frequency = 3                          → LAVAR ROUPA, LAVAR LOUÇA
-- [H] frequency = 7 (diário)                 → REGAR PLANTAS
--
-- CASOS DE tb_user_habit_day MAPEADOS
-- [I]  Todos os 7 dias               → REGAR PLANTAS
-- [J]  Somente dias úteis (seg-sex)  → BANHO LONGO
-- [K]  Somente fim de semana         → LAVAR CARRO
-- [L]  Dias alternados (seg/qua/sex) → LAVAR ROUPA
-- [M]  Dias não-consecutivos mistos  → LAVAR QUINTAL (qua + sab)
-- [N]  6 dias (seg-sex + sab)        → LAVAR LOUÇA
--
-- CAMADA ANALYTICS
-- stage.consumption_summary   → inserção direta (3 meses × 3 propriedades)
-- silver.*  e  gold.*         → populados via CALL silver.sp_load() e gold.sp_load()
-- ============================================================

BEGIN;

-- ============================================================
-- BLOCO 1 — DADOS CADASTRAIS (OLTP, schema public)
-- ============================================================
DO $$
DECLARE
    -- organização
    v_org_id        INTEGER;

    -- endereços
    v_addr_res_id   INTEGER;   -- residencial, Grande SP
    v_addr_com_id   INTEGER;   -- comercial,   Grande SP
    v_addr_soc_id   INTEGER;   -- social,       Lins

    -- propriedades
    v_prop_res_id   INTEGER;   -- residencial normal
    v_prop_com_id   INTEGER;   -- comercial (vinculada à org)
    v_prop_soc_id   INTEGER;   -- residencial social, outra região

    -- usuário
    v_user_id       INTEGER;

    -- user_habit ids
    v_uh_banho      INTEGER;
    v_uh_quintal    INTEGER;
    v_uh_roupa      INTEGER;
    v_uh_plantas    INTEGER;
    v_uh_carro      INTEGER;
    v_uh_louca      INTEGER;
BEGIN

    -- ----------------------------------------------------------
    -- 1. ORGANIZAÇÃO
    -- Representa uma empresa que monitora suas instalações.
    -- ----------------------------------------------------------
    INSERT INTO tb_organization (corporate_name, trade_name, cnpj, business_segment, declared_unit_count, registration_date)
    VALUES ('DELTA COMERCIO E SERVICOS LTDA', 'DELTA COMERCIO', '12345678000199', 'VAREJO', 3, '2022-03-01')
    ON CONFLICT (cnpj) DO NOTHING;
    SELECT id INTO v_org_id FROM tb_organization WHERE cnpj = '12345678000199';

    -- ----------------------------------------------------------
    -- 2. ENDEREÇOS (um por propriedade, regiões diferentes)
    -- ----------------------------------------------------------
    -- tb_address não tem UNIQUE — usa WHERE NOT EXISTS para idempotência
    -- Propriedade residencial — Grande SP (region_id=1)
    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT 1, '01777001', 'São Paulo', 'SP', -23.5492, -46.6341
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '01777001');
    SELECT id INTO v_addr_res_id FROM tb_address WHERE cep = '01777001';

    -- Propriedade comercial — Grande SP (region_id=1)
    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT 1, '01777002', 'São Paulo', 'SP', -23.5501, -46.6358
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '01777002');
    SELECT id INTO v_addr_com_id FROM tb_address WHERE cep = '01777002';

    -- Propriedade social — Lins (region_id=2, tarifa diferente)
    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT 2, '16900001', 'Lins', 'SP', -21.6778, -49.7430
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '16900001');
    SELECT id INTO v_addr_soc_id FROM tb_address WHERE cep = '16900001';

    -- ----------------------------------------------------------
    -- 3. PROPRIEDADES
    -- ----------------------------------------------------------
    -- Residencial normal: sem perfil operacional, sem organização
    INSERT INTO tb_property (name, type, classification_id, address_id, built_area_m2, registration_date)
    VALUES ('CASA DELTA FEIRA', 'CASA', 1, v_addr_res_id, 120.00, '2022-05-10')
    ON CONFLICT (name, address_id) DO NOTHING;
    SELECT id INTO v_prop_res_id FROM tb_property WHERE name = 'CASA DELTA FEIRA' AND address_id = v_addr_res_id;

    -- Comercial: com organização, com perfil operacional
    INSERT INTO tb_property (name, type, classification_id, address_id, organization_id, built_area_m2, registration_date)
    VALUES ('LOJA DELTA COMERCIO', 'PRÉDIO', 5, v_addr_com_id, v_org_id, 350.00, '2022-05-10')
    ON CONFLICT (name, address_id) DO NOTHING;
    SELECT id INTO v_prop_com_id FROM tb_property WHERE name = 'LOJA DELTA COMERCIO' AND address_id = v_addr_com_id;

    -- Residencial social: outra região, com perfil operacional, sem organização
    INSERT INTO tb_property (name, type, classification_id, address_id, built_area_m2, registration_date)
    VALUES ('CASA DELTA SOCIAL', 'CASA', 2, v_addr_soc_id, 80.00, '2023-01-20')
    ON CONFLICT (name, address_id) DO NOTHING;
    SELECT id INTO v_prop_soc_id FROM tb_property WHERE name = 'CASA DELTA SOCIAL' AND address_id = v_addr_soc_id;

    -- ----------------------------------------------------------
    -- 4. USUÁRIO DA FEIRA
    -- Senha = mesma do dataload padrão (argon2id).
    -- ----------------------------------------------------------
    INSERT INTO tb_user (name, email, password, phone, birth_date, registration_date, is_active, is_admin, is_manager)
    VALUES (
        'DELTA DEMO',
        'delta.demo@gmail.com',
        '$argon2id$v=19$m=19456,t=2,p=1$/7g/ZbFaPPZrkA3LTn2LRg$4QwINDoV6/255mLneaDiTGXyPiJ9tbli5AENCQGEMso',
        '(11) 99999-0000',
        '1995-06-15',
        '2022-05-10',
        TRUE,
        FALSE,
        TRUE
    )
    ON CONFLICT (email) DO NOTHING;
    SELECT id INTO v_user_id FROM tb_user WHERE email = 'delta.demo@gmail.com';

    RAISE NOTICE 'Usuário feira: id=%, email=delta.demo@gmail.com', v_user_id;
    RAISE NOTICE 'Propriedades: residencial=%, comercial=%, social=%', v_prop_res_id, v_prop_com_id, v_prop_soc_id;

    -- ----------------------------------------------------------
    -- 5. VÍNCULOS USUÁRIO ↔ PROPRIEDADES
    -- Um único usuário acessa as 3 propriedades.
    -- ----------------------------------------------------------
    INSERT INTO tb_user_property (user_id, property_id) VALUES (v_user_id, v_prop_res_id) ON CONFLICT (user_id, property_id) DO NOTHING;
    INSERT INTO tb_user_property (user_id, property_id) VALUES (v_user_id, v_prop_com_id) ON CONFLICT (user_id, property_id) DO NOTHING;
    INSERT INTO tb_user_property (user_id, property_id) VALUES (v_user_id, v_prop_soc_id) ON CONFLICT (user_id, property_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 6. VÍNCULO USUÁRIO ↔ ORGANIZAÇÃO
    -- Usuário é gestor da organização comercial.
    -- ----------------------------------------------------------
    INSERT INTO tb_user_organization (user_id, organization_id, association_date)
    VALUES (v_user_id, v_org_id, '2022-05-10')
    ON CONFLICT (user_id, organization_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 7. DISPOSITIVOS (um por propriedade)
    -- ----------------------------------------------------------
    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    VALUES ('ESP32-SP-FEIRA-01', v_prop_res_id, TRUE, '2022-05-15')
    ON CONFLICT (device_id) DO NOTHING;

    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    VALUES ('ESP32-SP-FEIRA-02', v_prop_com_id, TRUE, '2022-05-15')
    ON CONFLICT (device_id) DO NOTHING;

    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    VALUES ('ESP32-SP-FEIRA-03', v_prop_soc_id, TRUE, '2023-01-25')
    ON CONFLICT (device_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 8. FATURAS DE ÁGUA (3 meses para o usuário demo)
    -- tb_last_water_bill é por usuário, não por propriedade.
    -- ----------------------------------------------------------
    INSERT INTO tb_last_water_bill (user_id, month, total_value, m3_value) VALUES (v_user_id, '2026-08-01', 75.20, 10.50) ON CONFLICT (user_id, month) DO NOTHING;
    INSERT INTO tb_last_water_bill (user_id, month, total_value, m3_value) VALUES (v_user_id, '2026-09-01', 89.50, 12.50) ON CONFLICT (user_id, month) DO NOTHING;
    INSERT INTO tb_last_water_bill (user_id, month, total_value, m3_value) VALUES (v_user_id, '2026-10-01', 95.80, 13.40) ON CONFLICT (user_id, month) DO NOTHING;

    -- ----------------------------------------------------------
    -- 9. PERFIL OPERACIONAL DAS PROPRIEDADES
    -- Cobre os 4 valores possíveis de main_water_source.
    -- Propriedade residencial (prop_res) não tem perfil (sem registro).
    -- ----------------------------------------------------------
    INSERT INTO tb_property_operational_profile (property_id, main_water_source)
    VALUES (v_prop_com_id, 'CONCESSIONARIA')
    ON CONFLICT (property_id) DO NOTHING;

    INSERT INTO tb_property_operational_profile (property_id, main_water_source)
    VALUES (v_prop_soc_id, 'CISTERNA')
    ON CONFLICT (property_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 10. TURNOS DE OPERAÇÃO (só na propriedade comercial)
    -- tb_property_shift não tem UNIQUE — usa WHERE NOT EXISTS
    -- ----------------------------------------------------------
    INSERT INTO tb_property_shift (property_id, start_time, end_time)
    SELECT v_prop_com_id, '08:00', '12:00'
    WHERE NOT EXISTS (SELECT 1 FROM tb_property_shift WHERE property_id = v_prop_com_id AND start_time = '08:00');

    INSERT INTO tb_property_shift (property_id, start_time, end_time)
    SELECT v_prop_com_id, '13:00', '18:00'
    WHERE NOT EXISTS (SELECT 1 FROM tb_property_shift WHERE property_id = v_prop_com_id AND start_time = '13:00');

    -- ----------------------------------------------------------
    -- 11. TIPOS DE USO DA ÁGUA (só na propriedade comercial)
    -- ----------------------------------------------------------
    INSERT INTO tb_property_water_usage (property_id, water_usage_type_id) VALUES (v_prop_com_id, 1) ON CONFLICT (property_id, water_usage_type_id) DO NOTHING;
    INSERT INTO tb_property_water_usage (property_id, water_usage_type_id) VALUES (v_prop_com_id, 2) ON CONFLICT (property_id, water_usage_type_id) DO NOTHING;
    INSERT INTO tb_property_water_usage (property_id, water_usage_type_id) VALUES (v_prop_com_id, 3) ON CONFLICT (property_id, water_usage_type_id) DO NOTHING;
    INSERT INTO tb_property_water_usage (property_id, water_usage_type_id) VALUES (v_prop_com_id, 4) ON CONFLICT (property_id, water_usage_type_id) DO NOTHING;

    -- ----------------------------------------------------------
    -- 12. DIAS DE OPERAÇÃO
    -- ----------------------------------------------------------
    -- Comercial: seg(1) a sex(5)
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_com_id, 1) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_com_id, 2) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_com_id, 3) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_com_id, 4) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_com_id, 5) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;

    -- Social: seg(1), qua(3), sex(5)
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_soc_id, 1) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_soc_id, 3) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;
    INSERT INTO tb_property_operation_day (property_id, day_of_week_id) VALUES (v_prop_soc_id, 5) ON CONFLICT (property_id, day_of_week_id) DO NOTHING;

    -- Hábitos e dias NÃO são pré-populados aqui.
    -- O app adiciona os hábitos do usuário demo durante a demonstração,
    -- evitando violação da constraint uq_tb_user_habit_user_habit.

END;
$$;


-- ============================================================
-- BLOCO 2 — CONSUMO NA STAGE (3 meses × 3 propriedades)
-- ============================================================
-- mongo_id usa prefixo de 4 chars + YYYYMMDD + sufixo = 13 chars,
-- abaixo do limite de CHAR(24).
-- Janelas: manhã 06:00-12:00 e tarde 12:00-18:00 (6h cada).
-- lpm_average = litros / 360 minutos.
--
-- Volumes por propriedade (por janela):
--   fp01 → residencial normal:  manhã~88.5 L, tarde~115.0 L (~203 L/dia)
--   fp02 → comercial:           manhã~250.0 L, tarde~320.0 L (~570 L/dia)
--   fp03 → residencial social:  manhã~48.0 L, tarde~62.0 L  (~110 L/dia)
-- ============================================================

INSERT INTO stage.consumption_summary (
    mongo_id, device_id, user_id,
    window_started_at, window_finished_at,
    consumption_liters, lpm_average, anomaly_detected
)
SELECT
    RPAD(props.prefix || TO_CHAR(d, 'YYYYMMDD') || props.sfx, 13),
    props.device_id,
    (SELECT id::TEXT FROM tb_user WHERE email = 'delta.demo@gmail.com'),
    d + props.t_start,
    d + props.t_end,
    props.liters,
    ROUND((props.liters / 360.0)::NUMERIC, 3),
    FALSE
FROM
    generate_series('2026-08-01'::date, '2026-10-31'::date, '1 day') AS d,
    (VALUES
        -- prop residencial, prefixo fp01
        ('fp01', 'ESP32-SP-FEIRA-01', 'a', TIME '06:00', TIME '12:00',  88.5),
        ('fp01', 'ESP32-SP-FEIRA-01', 'b', TIME '12:00', TIME '18:00', 115.0),
        -- prop comercial, prefixo fp02
        ('fp02', 'ESP32-SP-FEIRA-02', 'a', TIME '06:00', TIME '12:00', 250.0),
        ('fp02', 'ESP32-SP-FEIRA-02', 'b', TIME '12:00', TIME '18:00', 320.0),
        -- prop social, prefixo fp03
        ('fp03', 'ESP32-SP-FEIRA-03', 'a', TIME '06:00', TIME '12:00',  48.0),
        ('fp03', 'ESP32-SP-FEIRA-03', 'b', TIME '12:00', TIME '18:00',  62.0)
    ) AS props(prefix, device_id, sfx, t_start, t_end, liters)
ORDER BY d, props.prefix, props.sfx
ON CONFLICT (mongo_id) DO NOTHING;

-- Anomalias em 3 datas distintas (uma por propriedade).
UPDATE stage.consumption_summary SET consumption_liters = 310.0, lpm_average = 0.861, anomaly_detected = TRUE
WHERE TRIM(mongo_id) = 'fp0120260808b';

UPDATE stage.consumption_summary SET consumption_liters = 650.0, lpm_average = 1.806, anomaly_detected = TRUE
WHERE TRIM(mongo_id) = 'fp0220260916a';

UPDATE stage.consumption_summary SET consumption_liters = 195.0, lpm_average = 0.542, anomaly_detected = TRUE
WHERE TRIM(mongo_id) = 'fp0320261025b';


-- ============================================================
-- BLOCO 3 — CAMADA ANALYTICS (Silver e Gold via ETL)
-- ============================================================
-- Silver: lê stage.consumption_summary + OLTP para popular
--   ft_consumption_reading, ft_consumption_daily, dm_property,
--   dm_person e ft_water_bill.
-- Gold: lê Silver para popular dm_date, dm_property, dm_person,
--   ft_consumption_daily e ft_water_bill_monthly.
-- Os procedimentos são idempotentes (ON CONFLICT), portanto não
-- duplicam dados já existentes de outros usuários.
-- ============================================================
CALL silver.sp_load();
CALL gold.sp_load();

COMMIT;
