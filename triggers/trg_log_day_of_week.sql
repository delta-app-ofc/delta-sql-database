CREATE TRIGGER trg_log_day_of_week
AFTER INSERT OR UPDATE OR DELETE
ON tb_day_of_week
FOR EACH ROW
EXECUTE FUNCTION fn_log_day_of_week();