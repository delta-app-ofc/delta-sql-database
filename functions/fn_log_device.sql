CREATE OR REPLACE FUNCTION fn_log_device()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_device
        (
              operation
            , executed_by
            , executed_at
            , id_device
            , device_id
            , property_id
            , is_active
            , installation_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.device_id
            , OLD.property_id
            , OLD.is_active
            , OLD.installation_date
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_device
        (
              operation
            , executed_by
            , executed_at
            , id_device
            , device_id
            , property_id
            , is_active
            , installation_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.device_id
            , NEW.property_id
            , NEW.is_active
            , NEW.installation_date
        );

        RETURN NEW;

    END IF;

END;
$$;