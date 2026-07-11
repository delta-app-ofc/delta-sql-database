CREATE OR REPLACE FUNCTION fn_log_user_habit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user_habit
        (
              operation
            , executed_by
            , executed_at
            , user_habit_id
            , user_id
            , habit_id
            , frequency
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_id
            , OLD.habit_id
            , OLD.frequency
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user_habit
        (
              operation
            , executed_by
            , executed_at
            , user_habit_id
            , user_id
            , habit_id
            , frequency
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_id
            , NEW.habit_id
            , NEW.frequency
        );

        RETURN NEW;

    END IF;

END;
$$;