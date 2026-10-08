CREATE TRIGGER trg_log_organization
AFTER INSERT OR UPDATE OR DELETE
ON tb_organization
FOR EACH ROW
EXECUTE FUNCTION fn_log_organization();
