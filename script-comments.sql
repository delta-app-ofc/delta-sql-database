-- Gera COMMENT ON COLUMN a partir de tb_data_catalog (fonte única das descrições).
-- Rodar depois de script-catalogo-dados.sql. Pode ser reexecutado sem problema.
--
-- 1) Tabelas funcionais: comentário = descrição + regra de negócio + nível de acesso.
-- 2) Tabelas tb_log_*: copiam o comentário da coluna de mesmo nome na tabela principal.
--    A coluna id da principal vira <entidade>_id no log (ex.: tb_habit.id -> tb_log_habit.habit_id),
--    e as colunas de auditoria têm comentário fixo.

BEGIN;

DO $$
DECLARE
    item RECORD;
BEGIN
    FOR item IN
        SELECT table_name, column_name, description, business_rule, access_level
        FROM tb_data_catalog
    LOOP
        -- Ignora linhas do catálogo cuja tabela/coluna não existe no schema public.
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name   = item.table_name
              AND column_name  = item.column_name
        ) THEN
            EXECUTE format(
                'COMMENT ON COLUMN public.%I.%I IS %L',
                item.table_name,
                item.column_name,
                item.description
                    || COALESCE(' Regra: ' || item.business_rule, '')
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

COMMIT;
