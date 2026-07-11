CREATE OR REPLACE FUNCTION fn_log_habit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_habit
        (
              operation
            , executed_by
            , executed_at
            , habit_id
            , name
            , description
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
            , OLD.description
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_habit
        (
              operation
            , executed_by
            , executed_at
            , habit_id
            , name
            , description
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
            , NEW.description
        );

        RETURN NEW;

    END IF;

END;
$$;