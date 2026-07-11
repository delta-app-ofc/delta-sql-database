CREATE OR REPLACE FUNCTION fn_log_address()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_address
        (
              operation
            , executed_by
            , executed_at
            , address_id
            , region_id
            , cep
            , city
            , state
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.region_id
            , OLD.cep
            , OLD.city
            , OLD.state
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_address
        (
              operation
            , executed_by
            , executed_at
            , address_id
            , region_id
            , cep
            , city
            , state
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.region_id
            , NEW.cep
            , NEW.city
            , NEW.state
        );

        RETURN NEW;

    END IF;

END;
$$;