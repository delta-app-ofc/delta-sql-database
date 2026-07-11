CREATE OR REPLACE FUNCTION fn_log_user_property()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user_property
        (
              operation
            , executed_by
            , executed_at
            , user_property_id
            , user_id
            , property_id
            , association_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_id
            , OLD.property_id
            , OLD.association_date
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user_property
        (
              operation
            , executed_by
            , executed_at
            , user_property_id
            , user_id
            , property_id
            , association_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_id
            , NEW.property_id
            , NEW.association_date
        );

        RETURN NEW;

    END IF;

END;
$$;