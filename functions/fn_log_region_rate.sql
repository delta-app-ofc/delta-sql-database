CREATE OR REPLACE FUNCTION fn_log_region_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_region_rate
        (
              operation
            , executed_by
            , executed_at
            , region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.region_id
            , OLD.m3_value
            , OLD.initial_validity
            , OLD.final_validity
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_region_rate
        (
              operation
            , executed_by
            , executed_at
            , region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.region_id
            , NEW.m3_value
            , NEW.initial_validity
            , NEW.final_validity
        );

        RETURN NEW;

    END IF;

END;
$$;