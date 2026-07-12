CREATE TRIGGER trg_log_user_habit
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_habit
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_habit();