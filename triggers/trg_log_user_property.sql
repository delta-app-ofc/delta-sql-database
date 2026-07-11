CREATE TRIGGER trg_log_user_property
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_property
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_property();