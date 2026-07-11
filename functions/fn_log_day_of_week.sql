CREATE OR REPLACE FUNCTION fn_log_day_of_week()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_day_of_week
        (
              operation
            , executed_by
            , executed_at
            , day_of_week_id
            , name
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_day_of_week
        (
              operation
            , executed_by
            , executed_at
            , day_of_week_id
            , name
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
        );

        RETURN NEW;

    END IF;

END;
$$;


CREATE TRIGGER trg_log_day_of_week
AFTER INSERT OR UPDATE OR DELETE
ON tb_day_of_week
FOR EACH ROW
EXECUTE FUNCTION fn_log_day_of_week();