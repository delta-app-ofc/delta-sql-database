-- Catálogo técnico de metadados do schema. Uma linha
-- por coluna de cada tabela funcional do sistema, não cobre as tabelas de
-- auditoria (tb_log_*), que são espelhos automáticos das tabelas principais
-- e não agregam metadado novo. Populado em script-catalogo-dados.sql.
--
--   PUBLICO  - valor de referência, sem qualquer sensibilidade
--   INTERNO  - dado operacional do negócio, sem identificar pessoa diretamente
--   RESTRITO - identifica pessoa/local com mais precisão, ou é dado administrativo
--   SENSIVEL - credencial ou PII sob LGPD (e-mail, telefone, senha, data de nascimento)
CREATE TABLE tb_data_catalog (
      id                    SERIAL      PRIMARY KEY
    , table_name            VARCHAR(60) NOT NULL
    , column_name           VARCHAR(60) NOT NULL
    , data_type             VARCHAR(60) NOT NULL
    , description           TEXT        NOT NULL
    , business_rule         TEXT
    , access_level          VARCHAR(20) NOT NULL
      CONSTRAINT chk_tb_data_catalog_access_level
        CHECK (access_level IN ('PUBLICO', 'INTERNO', 'RESTRITO', 'SENSIVEL'))
    , CONSTRAINT uq_tb_data_catalog_table_column
        UNIQUE (table_name, column_name)
);
