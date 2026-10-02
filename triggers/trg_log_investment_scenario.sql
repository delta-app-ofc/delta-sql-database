CREATE TRIGGER trg_log_investment_scenario
AFTER INSERT OR UPDATE OR DELETE
ON tb_investment_scenario
FOR EACH ROW
EXECUTE FUNCTION fn_log_investment_scenario();
