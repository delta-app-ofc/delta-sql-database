-- ============================================================
-- DATALOAD DA ORGANIZAÇÃO DO USUÁRIO JOTA (jota@delta.com)
-- ============================================================
-- Cria a organização JOTA ALIMENTOS (gestor: jota), 3 unidades
-- comerciais de áreas diferentes, dispositivos e 3 meses de consumo
-- na stage; depois roda o ETL Silver/Gold.
--
-- As unidades têm áreas diferentes de propósito: o ranking do Redis
-- compara L/m²·dia, então a menor unidade pode ser a mais eficiente
-- mesmo consumindo menos ou mais litros no total.
--
-- Pré-requisito: usuário jota@delta.com já cadastrado (o script do
-- jota residencial usa o id 204; aqui o id é buscado pelo e-mail).
-- Idempotente: pode ser re-executado sem duplicar dados.
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_user_id     INTEGER;
    v_org_id      INTEGER;
    v_class_id    INTEGER;
    v_region_id   INTEGER;
    v_addr_a      INTEGER;
    v_addr_b      INTEGER;
    v_addr_c      INTEGER;
BEGIN
    SELECT id INTO v_user_id FROM tb_user WHERE LOWER(email) = 'jota@delta.com';
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário jota@delta.com não encontrado; cadastre-o antes.';
    END IF;

    SELECT id INTO v_class_id  FROM tb_property_classification WHERE name = 'COMERCIAL_NORMAL_INDUSTRIAL';
    SELECT id INTO v_region_id FROM tb_region WHERE name = 'GRANDE_SP';

    -- Organização
    INSERT INTO tb_organization (corporate_name, trade_name, cnpj, business_segment, declared_unit_count, registration_date)
    VALUES ('JOTA ALIMENTOS LTDA', 'JOTA ALIMENTOS', '98765432000110', 'VAREJO', 3, '2023-03-01')
    ON CONFLICT (cnpj) DO NOTHING;
    SELECT id INTO v_org_id FROM tb_organization WHERE cnpj = '98765432000110';

    -- Endereços (tb_address não tem UNIQUE: usa NOT EXISTS)
    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT v_region_id, '04571010', 'São Paulo', 'SP', -23.6061, -46.6970
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '04571010');
    SELECT id INTO v_addr_a FROM tb_address WHERE cep = '04571010';

    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT v_region_id, '05425070', 'São Paulo', 'SP', -23.5614, -46.6932
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '05425070');
    SELECT id INTO v_addr_b FROM tb_address WHERE cep = '05425070';

    INSERT INTO tb_address (region_id, cep, city, state, latitude, longitude)
    SELECT v_region_id, '03047000', 'São Paulo', 'SP', -23.5390, -46.6190
    WHERE NOT EXISTS (SELECT 1 FROM tb_address WHERE cep = '03047000');
    SELECT id INTO v_addr_c FROM tb_address WHERE cep = '03047000';

    -- Unidades comerciais da organização (áreas bem diferentes)
    INSERT INTO tb_property (name, type, classification_id, address_id, organization_id, built_area_m2, registration_date)
    VALUES ('JOTA LOJA MOEMA', 'PRÉDIO', v_class_id, v_addr_a, v_org_id, 650.00, '2023-03-01')
    ON CONFLICT (name, address_id) DO NOTHING;
    INSERT INTO tb_property (name, type, classification_id, address_id, organization_id, built_area_m2, registration_date)
    VALUES ('JOTA LOJA PINHEIROS', 'PRÉDIO', v_class_id, v_addr_b, v_org_id, 1200.00, '2023-03-01')
    ON CONFLICT (name, address_id) DO NOTHING;
    INSERT INTO tb_property (name, type, classification_id, address_id, organization_id, built_area_m2, registration_date)
    VALUES ('JOTA CENTRO DE DISTRIBUICAO', 'PRÉDIO', v_class_id, v_addr_c, v_org_id, 3200.00, '2023-03-01')
    ON CONFLICT (name, address_id) DO NOTHING;

    -- Vínculo usuário ↔ organização (gestor)
    INSERT INTO tb_user_organization (user_id, organization_id, association_date)
    VALUES (v_user_id, v_org_id, '2023-03-01')
    ON CONFLICT (user_id, organization_id) DO NOTHING;

    -- Dispositivos (um por unidade)
    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    SELECT 'ESP32-SP-JOTA-ORG-01', id, TRUE, '2023-03-10' FROM tb_property WHERE name = 'JOTA LOJA MOEMA'
    ON CONFLICT (device_id) DO NOTHING;
    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    SELECT 'ESP32-SP-JOTA-ORG-02', id, TRUE, '2023-03-10' FROM tb_property WHERE name = 'JOTA LOJA PINHEIROS'
    ON CONFLICT (device_id) DO NOTHING;
    INSERT INTO tb_device (device_id, property_id, is_active, installation_date)
    SELECT 'ESP32-SP-JOTA-ORG-03', id, TRUE, '2023-03-10' FROM tb_property WHERE name = 'JOTA CENTRO DE DISTRIBUICAO'
    ON CONFLICT (device_id) DO NOTHING;

    -- Perfil operacional das unidades
    INSERT INTO tb_property_operational_profile (property_id, main_water_source)
    SELECT id, 'CONCESSIONARIA' FROM tb_property WHERE organization_id = v_org_id
    ON CONFLICT (property_id) DO NOTHING;

    RAISE NOTICE 'Organização jota: id=% (usuário %)', v_org_id, v_user_id;
END;
$$;

-- ============================================================
-- CONSUMO NA STAGE (3 meses × 3 unidades, 2 janelas por dia)
-- Litros por dia (soma das 2 janelas): Moema 130, Pinheiros 420, CD 900
-- => L/m²·dia: 0,20 / 0,35 / 0,28
-- ============================================================
INSERT INTO stage.consumption_summary (
    mongo_id, device_id, user_id,
    window_started_at, window_finished_at,
    consumption_liters, lpm_average, anomaly_detected
)
SELECT
    RPAD(props.prefix || TO_CHAR(d, 'YYYYMMDD') || props.sfx, 13),
    props.device_id,
    (SELECT id::TEXT FROM tb_user WHERE LOWER(email) = 'jota@delta.com'),
    d + props.t_start,
    d + props.t_end,
    props.liters,
    ROUND((props.liters / 360.0)::NUMERIC, 3),
    FALSE
FROM
    generate_series('2026-08-01'::date, '2026-10-31'::date, '1 day') AS d,
    (VALUES
        ('jo01', 'ESP32-SP-JOTA-ORG-01', 'a', TIME '06:00', TIME '12:00',  60.0),
        ('jo01', 'ESP32-SP-JOTA-ORG-01', 'b', TIME '12:00', TIME '18:00',  70.0),
        ('jo02', 'ESP32-SP-JOTA-ORG-02', 'a', TIME '06:00', TIME '12:00', 190.0),
        ('jo02', 'ESP32-SP-JOTA-ORG-02', 'b', TIME '12:00', TIME '18:00', 230.0),
        ('jo03', 'ESP32-SP-JOTA-ORG-03', 'a', TIME '06:00', TIME '12:00', 420.0),
        ('jo03', 'ESP32-SP-JOTA-ORG-03', 'b', TIME '12:00', TIME '18:00', 480.0)
    ) AS props(prefix, device_id, sfx, t_start, t_end, liters)
ORDER BY d, props.prefix, props.sfx
ON CONFLICT (mongo_id) DO NOTHING;

-- Uma anomalia no centro de distribuição (indício para o agente de vazamento)
UPDATE stage.consumption_summary SET consumption_liters = 1100.0, lpm_average = 3.056, anomaly_detected = TRUE
WHERE TRIM(mongo_id) = 'jo0320261015b';

-- ============================================================
-- ETL: Silver e Gold
-- ============================================================
CALL silver.sp_load();
CALL gold.sp_load();

COMMIT;
