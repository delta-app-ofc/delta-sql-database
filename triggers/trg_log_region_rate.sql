CREATE TRIGGER trg_log_region_rate
AFTER INSERT OR UPDATE OR DELETE
ON tb_region_rate
FOR EACH ROW
EXECUTE FUNCTION fn_log_region_rate();