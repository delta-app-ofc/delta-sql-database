CREATE OR REPLACE FUNCTION fn_user_habits(
    p_user_id INTEGER
)
RETURNS TABLE (
    name             VARCHAR,
    category         VARCHAR,
    frequency        INTEGER,
    days             VARCHAR[],
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
        , h.category
        , uh.frequency
        , COALESCE(
              array_agg(d.name ORDER BY d.id) FILTER (WHERE d.id IS NOT NULL)
            , ARRAY[]::VARCHAR[]
          )
        , uh.start_time
        , uh.end_time
        , uh.estimated_liters
      FROM tb_user_habit uh
      JOIN tb_habit h
        ON h.id = uh.habit_id
      LEFT JOIN tb_user_habit_day uhd
        ON uhd.user_habit_id = uh.id
      LEFT JOIN tb_day_of_week d
        ON d.id = uhd.day_of_week_id
     WHERE uh.user_id = p_user_id
     GROUP BY uh.id, h.name, h.category
     ORDER BY h.name;

END;
$$;
