CREATE OR REPLACE FUNCTION fn_user_habits_by_day(
    p_user_id INTEGER,
    p_day     VARCHAR
)
RETURNS TABLE (
    name             VARCHAR,
    frequency        INTEGER,
    start_time       TIME,
    end_time         TIME,
    estimated_liters NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
          h.name
        , uh.frequency
        , uh.start_time
        , uh.end_time
        , uh.estimated_liters
      FROM tb_user_habit uh
      JOIN tb_habit h
        ON h.id = uh.habit_id
      JOIN tb_user_habit_day uhd
        ON uhd.user_habit_id = uh.id
      JOIN tb_day_of_week d
        ON d.id = uhd.day_of_week_id
     WHERE uh.user_id = p_user_id
       AND d.name = UPPER(p_day)
     ORDER BY uh.start_time NULLS LAST, h.name;

END;
$$;
