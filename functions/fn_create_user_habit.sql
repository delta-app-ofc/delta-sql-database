DROP FUNCTION IF EXISTS fn_create_user_habit(INTEGER, VARCHAR, INTEGER, VARCHAR[]);

CREATE OR REPLACE FUNCTION fn_create_user_habit(
    p_user_id    INTEGER,
    p_habit_name VARCHAR,
    p_frequency  INTEGER,
    p_days       VARCHAR[] DEFAULT ARRAY[]::VARCHAR[],
    p_start_time TIME      DEFAULT NULL,
    p_end_time   TIME      DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_habit_id      INTEGER;
    v_user_habit_id INTEGER;
    v_days_count    INTEGER;
    v_inserted      INTEGER;
BEGIN

    SELECT h.id
      INTO v_habit_id
      FROM tb_habit h
     WHERE h.name = UPPER(p_habit_name);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hábito % não existe no catálogo.', p_habit_name;
    END IF;


    -- O mesmo hábito pode ser cadastrado mais de uma vez (horários ou dias diferentes).
    -- Conflito de dia + horário é barrado pela trigger trg_check_user_habit_day_conflict.
    INSERT INTO tb_user_habit (user_id, habit_id, frequency, start_time, end_time)
    VALUES (p_user_id, v_habit_id, p_frequency, p_start_time, p_end_time)
    RETURNING id INTO v_user_habit_id;


    SELECT COUNT(DISTINCT UPPER(x))
      INTO v_days_count
      FROM unnest(p_days) AS x;

    INSERT INTO tb_user_habit_day (user_habit_id, day_of_week_id)
    SELECT v_user_habit_id, d.id
      FROM tb_day_of_week d
     WHERE d.name IN (SELECT UPPER(x) FROM unnest(p_days) AS x);

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    IF v_inserted <> v_days_count THEN
        RAISE EXCEPTION 'Dia da semana inválido em %.', p_days;
    END IF;


    RETURN v_user_habit_id;

END;
$$;
