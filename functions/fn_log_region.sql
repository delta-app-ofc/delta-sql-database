CREATE OR REPLACE FUNCTION fn_log_region()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_region
        WHERE region_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_region
        WHERE region_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_region.';


        INSERT INTO tb_log_region
        (
              region_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_region. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_region
        (
              region_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_region.';


        INSERT INTO tb_log_region
        (
              region_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;