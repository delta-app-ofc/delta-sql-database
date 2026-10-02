CREATE TRIGGER trg_log_property_operation_day
AFTER INSERT OR UPDATE OR DELETE
ON tb_property_operation_day
FOR EACH ROW
EXECUTE FUNCTION fn_log_property_operation_day();
