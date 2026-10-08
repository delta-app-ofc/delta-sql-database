CREATE TRIGGER trg_log_property_water_usage
AFTER INSERT OR UPDATE OR DELETE
ON tb_property_water_usage
FOR EACH ROW
EXECUTE FUNCTION fn_log_property_water_usage();
