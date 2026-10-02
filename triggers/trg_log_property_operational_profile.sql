CREATE TRIGGER trg_log_property_operational_profile
AFTER INSERT OR UPDATE OR DELETE
ON tb_property_operational_profile
FOR EACH ROW
EXECUTE FUNCTION fn_log_property_operational_profile();
