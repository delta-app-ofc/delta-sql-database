CREATE TRIGGER trg_log_property_shift
AFTER INSERT OR UPDATE OR DELETE
ON tb_property_shift
FOR EACH ROW
EXECUTE FUNCTION fn_log_property_shift();
