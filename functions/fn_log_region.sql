CREATE OR REPLACE FUNCTION fn_log_region()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS 
$$ 
BEGIN

    IF TG_OP = 'DELETE' THEN
        INSERT INTO tb_log_region
        (
              operation
            , executed_by
            , executed_at
            , region_id
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
        INSERT INTO tb_log_region
        (
              operation
            , executed_by
            , executed_at
            , region_id
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