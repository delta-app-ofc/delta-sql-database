CREATE TRIGGER trg_check_user_habit_day_conflict
BEFORE INSERT OR UPDATE
ON tb_user_habit_day
FOR EACH ROW
EXECUTE FUNCTION fn_check_user_habit_day_conflict();

CREATE TRIGGER trg_check_user_habit_conflict
BEFORE UPDATE OF habit_id, start_time
ON tb_user_habit
FOR EACH ROW
EXECUTE FUNCTION fn_check_user_habit_conflict();
