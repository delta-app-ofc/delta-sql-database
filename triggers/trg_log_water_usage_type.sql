CREATE TRIGGER trg_log_water_usage_type
AFTER INSERT OR UPDATE OR DELETE
ON tb_water_usage_type
FOR EACH ROW
EXECUTE FUNCTION fn_log_water_usage_type();
