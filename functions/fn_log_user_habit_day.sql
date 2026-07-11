CREATE OR REPLACE FUNCTION fn_log_user_habit_day()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user_habit_day
        (
              operation
            , executed_by
            , executed_at
            , user_habit_day_id
            , user_habit_id
            , day_of_week_id
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_habit_id
            , OLD.day_of_week_id
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user_habit_day
        (
              operation
            , executed_by
            , executed_at
            , user_habit_day_id
            , user_habit_id
            , day_of_week_id
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_habit_id
            , NEW.day_of_week_id
        );

        RETURN NEW;

    END IF;

END;
$$;