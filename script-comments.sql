-- Gera COMMENT ON COLUMN a partir de tb_data_catalog (fonte única das descrições).
-- Rodar depois de script-catalogo-dados.sql. Pode ser reexecutado sem problema.
--
-- 1) Tabelas e views (public, stage, silver, gold, dw): comentário = descrição + regra de negócio + nível de acesso.
-- 2) Tabelas tb_log_*: copiam o comentário da coluna de mesmo nome na tabela principal.
--    A coluna id da principal vira <entidade>_id no log (ex.: tb_habit.id -> tb_log_habit.habit_id),
--    e as colunas de auditoria têm comentário fixo.

BEGIN;

DO $$
DECLARE
    item RECORD;
    schema_name TEXT;
    object_name TEXT;
BEGIN
    FOR item IN
        SELECT table_name, column_name, description, business_rule, access_level
        FROM tb_data_catalog
    LOOP
        -- Nomes do catálogo podem vir como schema.tabela (stage, silver, gold, dw);
        -- sem schema, assume public.
        IF position('.' IN item.table_name) > 0 THEN
            schema_name := split_part(item.table_name, '.', 1);
            object_name := split_part(item.table_name, '.', 2);
        ELSE
            schema_name := 'public';
            object_name := item.table_name;
        END IF;

        -- Ignora linhas do catálogo cuja tabela/coluna não existe no banco.
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = schema_name
              AND table_name   = object_name
              AND column_name  = item.column_name
        ) THEN
            EXECUTE format(
                'COMMENT ON COLUMN %I.%I.%I IS %L',
                schema_name,
                object_name,
                item.column_name,
                item.description
                    || COALESCE(' Regra: ' || NULLIF(item.business_rule, ''), '')
                    || ' [Acesso: ' || item.access_level || ']'
            );
        END IF;
    END LOOP;
END $$;

DO $$
DECLARE
    item RECORD;
    source_table TEXT;
    source_column TEXT;
    source_comment TEXT;
BEGIN
    FOR item IN
        SELECT c.table_name, c.column_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.table_name LIKE 'tb\_log\_%'
    LOOP
        source_table := 'tb_' || substr(item.table_name, 8);

        IF item.column_name = 'id' THEN
            source_comment := 'Identificador do registro de auditoria.';
        ELSIF item.column_name = 'operation' THEN
            source_comment := 'Operação auditada: INSERT, UPDATE ou DELETE.';
        ELSIF item.column_name = 'executed_by' THEN
            source_comment := 'Usuário do banco que executou a operação.';
        ELSIF item.column_name = 'executed_at' THEN
            source_comment := 'Data e hora em que a operação foi executada.';
        ELSIF item.column_name = 'previous_log_id' THEN
            source_comment := 'Registro de auditoria anterior da mesma linha (encadeia o histórico).';
        ELSIF item.column_name = 'log_description' THEN
            source_comment := 'Descrição textual da alteração registrada.';
        ELSE
            -- <entidade>_id no log corresponde à coluna id da tabela principal.
            IF item.column_name = substr(item.table_name, 8) || '_id' THEN
                source_column := 'id';
            ELSE
                source_column := item.column_name;
            END IF;

            -- tb_log_rpa, por exemplo, não é espelho de nenhuma tabela principal.
            source_comment := NULL;

            IF to_regclass(format('public.%I', source_table)) IS NOT NULL THEN
                SELECT col_description(a.attrelid, a.attnum)
                INTO source_comment
                FROM pg_attribute a
                WHERE a.attrelid = to_regclass(format('public.%I', source_table))
                  AND a.attname = source_column
                  AND NOT a.attisdropped;
            END IF;
        END IF;

        IF source_comment IS NOT NULL THEN
            EXECUTE format(
                'COMMENT ON COLUMN public.%I.%I IS %L',
                item.table_name,
                item.column_name,
                source_comment
            );
        END IF;
    END LOOP;
END $$;

-- 3) Colunas que o catálogo não alcança: nome do log fora do padrão <entidade>_id,
--    tabela do próprio catálogo e tb_device_credential (criada fora dos scripts do repositório).
DO $$
BEGIN
    IF to_regclass('public.tb_log_device') IS NOT NULL THEN
        COMMENT ON COLUMN public.tb_log_device.device_id_log IS
            'Identificador (id) do device na tabela tb_device no momento da operação auditada.';
    END IF;

    IF to_regclass('public.tb_log_property_operational_profile') IS NOT NULL THEN
        COMMENT ON COLUMN public.tb_log_property_operational_profile.property_operational_profile_id IS
            'Identificador do perfil operacional auditado (mesmo valor de property_id, a chave de tb_property_operational_profile).';
    END IF;

    IF to_regclass('public.tb_data_catalog') IS NOT NULL THEN
        COMMENT ON COLUMN public.tb_data_catalog.id IS 'Identificador da linha do catálogo.';
        COMMENT ON COLUMN public.tb_data_catalog.table_name IS 'Nome da tabela descrita.';
        COMMENT ON COLUMN public.tb_data_catalog.column_name IS 'Nome da coluna descrita.';
        COMMENT ON COLUMN public.tb_data_catalog.data_type IS 'Tipo de dado da coluna.';
        COMMENT ON COLUMN public.tb_data_catalog.description IS 'Descrição da coluna.';
        COMMENT ON COLUMN public.tb_data_catalog.business_rule IS 'Regra de negócio ou restrição aplicada à coluna.';
        COMMENT ON COLUMN public.tb_data_catalog.access_level IS 'Nível de acesso: PUBLICO, INTERNO, RESTRITO ou SENSIVEL.';
    END IF;

    IF to_regclass('public.tb_device_credential') IS NOT NULL THEN
        COMMENT ON COLUMN public.tb_device_credential.id IS 'Identificador da credencial do device.';
        COMMENT ON COLUMN public.tb_device_credential.device_id IS 'Device (tb_device.id) dono da credencial.';
        COMMENT ON COLUMN public.tb_device_credential.key_hash IS 'Hash da chave do device, 64 caracteres, único. Nunca guarda a chave em texto puro. [Acesso: SENSIVEL]';
        COMMENT ON COLUMN public.tb_device_credential.created_at IS 'Data e hora de criação da credencial.';
        COMMENT ON COLUMN public.tb_device_credential.revoked_at IS 'Data e hora da revogação; vazio enquanto a credencial está ativa. Não pode ser anterior à criação.';
        COMMENT ON COLUMN public.tb_device_credential.expires_at IS 'Data e hora de expiração; opcional, deve ser posterior à criação.';
        COMMENT ON COLUMN public.tb_device_credential.current_device_id IS 'Preenchido com o device_id enquanto a credencial está vigente e vazio após revogada; único, garante uma credencial vigente por device.';
    END IF;

    -- Views do schema dw cujas colunas o catálogo não descreve.
    IF to_regclass('dw.vw_ft_capex_comparison') IS NOT NULL THEN
        COMMENT ON COLUMN dw.vw_ft_capex_comparison.name IS 'Nome do cenário de investimento.';
        COMMENT ON COLUMN dw.vw_ft_capex_comparison.investment_value IS 'Valor investido no cenário, em reais.';
        COMMENT ON COLUMN dw.vw_ft_capex_comparison.reduction_pct IS 'Percentual de redução de consumo esperado.';
        COMMENT ON COLUMN dw.vw_ft_capex_comparison.annual_savings_value IS 'Economia anual estimada, em reais.';
        COMMENT ON COLUMN dw.vw_ft_capex_comparison.payback_months IS 'Meses para o investimento se pagar (base do ranking).';
        COMMENT ON COLUMN dw.vw_ft_consumption_daily.property_name IS 'Nome do imóvel.';
        COMMENT ON COLUMN dw.vw_ft_consumption_distribution.total_liters IS 'Total de litros consumidos por dia, usado nas estatísticas da distribuição.';
        COMMENT ON COLUMN dw.vw_ft_consumption_distribution.min_liters IS 'Menor consumo diário, em litros.';
        COMMENT ON COLUMN dw.vw_ft_consumption_distribution.q1_liters IS 'Primeiro quartil (25%) do consumo diário, em litros.';
        COMMENT ON COLUMN dw.vw_ft_consumption_distribution.q3_liters IS 'Terceiro quartil (75%) do consumo diário, em litros.';
        COMMENT ON COLUMN dw.vw_ft_consumption_distribution.max_liters IS 'Maior consumo diário, em litros.';
        COMMENT ON COLUMN dw.vw_ft_monthly_variation.property_name IS 'Nome do imóvel.';
        COMMENT ON COLUMN dw.vw_ft_monthly_variation.total_liters IS 'Total de litros consumidos no mês.';
        COMMENT ON COLUMN dw.vw_ft_monthly_variation.previous_month_liters IS 'Total de litros consumidos no mês anterior.';
        COMMENT ON COLUMN dw.vw_ft_property_ranking.property_name IS 'Nome do imóvel.';
        COMMENT ON COLUMN dw.vw_ft_property_ranking.total_liters IS 'Total de litros consumidos pelo imóvel no período.';
        COMMENT ON COLUMN dw.vw_ft_property_ranking.total_cost IS 'Custo total do consumo do imóvel, em reais.';
        COMMENT ON COLUMN dw.vw_ft_residential_efficiency_ranking.person_name IS 'Nome da pessoa dona da fatura.';
        COMMENT ON COLUMN dw.vw_ft_residential_efficiency_ranking.reference_month IS 'Mês de referência da fatura (primeiro dia do mês).';
        COMMENT ON COLUMN dw.vw_ft_residential_efficiency_ranking.m3_value IS 'Consumo faturado no mês, em m³ (base do ranking).';
        COMMENT ON COLUMN dw.vw_ft_residential_efficiency_ranking.total_value IS 'Valor total da fatura, em reais.';
    END IF;
END $$;

COMMIT;
