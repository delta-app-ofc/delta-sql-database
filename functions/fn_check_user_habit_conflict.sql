-- Regra: o mesmo usuário não pode ter o mesmo hábito, no mesmo dia da semana,
-- com o mesmo horário de início (NULL conta como "sem horário", igual a outro NULL).

-- Dispara ao inserir/alterar um dia em tb_user_habit_day.
CREATE OR REPLACE FUNCTION fn_check_user_habit_day_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS (
        SELECT 1
          FROM tb_user_habit me
          JOIN tb_user_habit other
            ON other.user_id = me.user_id
           AND other.habit_id = me.habit_id
           AND other.id <> me.id
           AND other.start_time IS NOT DISTINCT FROM me.start_time
          JOIN tb_user_habit_day other_day
            ON other_day.user_habit_id = other.id
           AND other_day.day_of_week_id = NEW.day_of_week_id
         WHERE me.id = NEW.user_habit_id
    ) THEN
        RAISE EXCEPTION 'O usuário já possui esse hábito nesse dia e horário.';
    END IF;

    RETURN NEW;

END;
$$;

-- Dispara ao trocar o hábito ou o horário em tb_user_habit (os dias já existem).
CREATE OR REPLACE FUNCTION fn_check_user_habit_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF EXISTS (
        SELECT 1
          FROM tb_user_habit other
          JOIN tb_user_habit_day other_day
            ON other_day.user_habit_id = other.id
          JOIN tb_user_habit_day my_day
            ON my_day.user_habit_id = NEW.id
           AND my_day.day_of_week_id = other_day.day_of_week_id
         WHERE other.user_id = NEW.user_id
           AND other.habit_id = NEW.habit_id
           AND other.id <> NEW.id
           AND other.start_time IS NOT DISTINCT FROM NEW.start_time
    ) THEN
        RAISE EXCEPTION 'O usuário já possui esse hábito nesse dia e horário.';
    END IF;

    RETURN NEW;

END;
$$;
