CREATE OR REPLACE FUNCTION fn_log_user()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user
        (
              operation
            , executed_by
            , executed_at
            , user_id
            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
            , OLD.email
            , OLD.phone
            , OLD.birth_date
            , OLD.registration_date
            , OLD.is_active
            , OLD.is_admin
            , OLD.is_manager
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user
        (
              operation
            , executed_by
            , executed_at
            , user_id
            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
            , NEW.email
            , NEW.phone
            , NEW.birth_date
            , NEW.registration_date
            , NEW.is_active
            , NEW.is_admin
            , NEW.is_manager
        );

        RETURN NEW;

    END IF;

END;
$$;