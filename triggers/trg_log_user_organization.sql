CREATE TRIGGER trg_log_user_organization
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_organization
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_organization();
