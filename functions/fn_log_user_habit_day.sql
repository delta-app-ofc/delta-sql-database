CREATE OR REPLACE FUNCTION fn_log_user_habit_day()

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
        FROM tb_log_user_habit_day
        WHERE user_habit_day_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_habit_day
        WHERE user_habit_day_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_user_habit_day.';


        INSERT INTO tb_log_user_habit_day
        (
              user_habit_day_id
            , user_habit_id
            , day_of_week_id

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_habit_id
            , NEW.day_of_week_id

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_user_habit_day. Campos alterados:';


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
                    old_value ||
                    '" | Valor novo: "' ||
                    new_value ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_user_habit_day
        (
              user_habit_day_id
            , user_habit_id
            , day_of_week_id

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_habit_id
            , NEW.day_of_week_id

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_user_habit_day.';


        INSERT INTO tb_log_user_habit_day
        (
              user_habit_day_id
            , user_habit_id
            , day_of_week_id

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.user_habit_id
            , OLD.day_of_week_id

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