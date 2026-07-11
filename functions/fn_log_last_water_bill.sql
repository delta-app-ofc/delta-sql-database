CREATE OR REPLACE FUNCTION fn_log_last_water_bill()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_last_water_bill
        (
              operation
            , executed_by
            , executed_at
            , last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_id
            , OLD.month
            , OLD.total_value
            , OLD.m3_value
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_last_water_bill
        (
              operation
            , executed_by
            , executed_at
            , last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_id
            , NEW.month
            , NEW.total_value
            , NEW.m3_value
        );

        RETURN NEW;

    END IF;

END;
$$;