CREATE TRIGGER trg_log_property_classification
AFTER INSERT OR UPDATE OR DELETE
ON tb_property_classification
FOR EACH ROW
EXECUTE FUNCTION fn_log_property_classification();
