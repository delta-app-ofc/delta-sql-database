CREATE OR REPLACE FUNCTION fn_log_property()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_property
        (
              operation
            , executed_by
            , executed_at
            , property_id
            , name
            , type
            , classification
            , address_id
            , registration_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
            , OLD.type
            , OLD.classification
            , OLD.address_id
            , OLD.registration_date
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_property
        (
              operation
            , executed_by
            , executed_at
            , property_id
            , name
            , type
            , classification
            , address_id
            , registration_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
            , NEW.type
            , NEW.classification
            , NEW.address_id
            , NEW.registration_date
        );

        RETURN NEW;

    END IF;

END;
$$;