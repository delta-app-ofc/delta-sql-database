DROP FUNCTION IF EXISTS fn_log_user();

CREATE OR REPLACE FUNCTION fn_log_user()

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
        FROM tb_log_user
        WHERE user_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_user
        WHERE user_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_user.';


        INSERT INTO tb_log_user
        (
              user_id

            , name
            , email
            , password
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager

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
            , NEW.email
            , NEW.password
            , NEW.phone
            , NEW.birth_date
            , NEW.registration_date
            , NEW.is_active
            , NEW.is_admin
            , NEW.is_manager

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_user. Campos alterados:';


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


        INSERT INTO tb_log_user
        (
              user_id

            , name
            , email
            , password
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager

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
            , NEW.email
            , NEW.password
            , NEW.phone
            , NEW.birth_date
            , NEW.registration_date
            , NEW.is_active
            , NEW.is_admin
            , NEW.is_manager

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_user.';


        INSERT INTO tb_log_user
        (
              user_id

            , name
            , email
            , password
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager

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
            , OLD.email
            , OLD.password
            , OLD.phone
            , OLD.birth_date
            , OLD.registration_date
            , OLD.is_active
            , OLD.is_admin
            , OLD.is_manager

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