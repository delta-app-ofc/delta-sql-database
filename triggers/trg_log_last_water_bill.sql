CREATE TRIGGER trg_log_last_water_bill
AFTER INSERT OR UPDATE OR DELETE
ON tb_last_water_bill
FOR EACH ROW
EXECUTE FUNCTION fn_log_last_water_bill();