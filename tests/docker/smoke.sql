DO $$
BEGIN
    IF to_regclass('public.tb_user') IS NULL THEN
        RAISE EXCEPTION 'Esperava encontrar a tabela public.tb_user';
    END IF;

    IF to_regclass('public.tb_property') IS NULL THEN
        RAISE EXCEPTION 'Esperava encontrar a tabela public.tb_property';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE contype = 'f'
    ) THEN
        RAISE EXCEPTION 'Esperava encontrar ao menos uma foreign key';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'fn_user_is_active'
    ) THEN
        RAISE EXCEPTION 'Esperava encontrar a função fn_user_is_active';
    END IF;
END
$$;

BEGIN;
INSERT INTO tb_region (name) VALUES ('GRANDE_SP');

DO $$
BEGIN
    BEGIN
        INSERT INTO tb_region (name) VALUES ('INVALID_REGION');
        RAISE EXCEPTION 'Esperava que chk_tb_region_name_values rejeitasse a região';
    EXCEPTION
        WHEN check_violation THEN NULL;
    END;
END
$$;
ROLLBACK;

SELECT 'Schema smoke checks passed.' AS result;
