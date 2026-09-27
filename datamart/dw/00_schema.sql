-- Esquema DW: so views (dw.vw_*) - a camada de consumo da BI, com CTEs +
-- window functions, lendo so do GOLD (exceto vw_audit_history_chain, que e
-- uma view de auditoria/governanca sobre tb_log_region_rate, nao uma view
-- dimensional - ver comentario nela).
CREATE SCHEMA IF NOT EXISTS dw;
