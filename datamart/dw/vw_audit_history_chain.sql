-- Estrutura avancada: CTE RECURSIVA. Reconstroi o historico completo de
-- mudancas de cada linha de tb_region_rate subindo a cadeia de
-- tb_log_region_rate.previous_log_id (trilha de auditoria que ja existe,
-- ver audit-tables/tb_log_region_rate.sql) - sem precisar de uma hierarquia
-- de gestores inventada. Le de tb_log_region_rate (schema public), nao do
-- gold: e uma view de auditoria/governanca, nao uma view dimensional.
--
-- Exemplo de consulta (historico de UMA tarifa especifica):
--   SELECT * FROM dw.vw_audit_history_chain WHERE region_rate_id = 5 ORDER BY level;
CREATE OR REPLACE VIEW dw.vw_audit_history_chain AS
WITH RECURSIVE chain AS (
    SELECT
          id
        , region_rate_id
        , m3_value
        , operation
        , executed_by
        , executed_at
        , previous_log_id
        , 1 AS level
    FROM tb_log_region_rate
    WHERE previous_log_id IS NULL

    UNION ALL

    SELECT
          l.id
        , l.region_rate_id
        , l.m3_value
        , l.operation
        , l.executed_by
        , l.executed_at
        , l.previous_log_id
        , c.level + 1
    FROM tb_log_region_rate l
    JOIN chain c ON l.previous_log_id = c.id
)
SELECT
      id AS log_id
    , region_rate_id
    , m3_value
    , operation
    , executed_by
    , executed_at
    , level
FROM chain;
