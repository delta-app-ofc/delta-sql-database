-- DATA ENGINEER
GRANT USAGE ON SCHEMA stage, silver, gold, dw TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL TABLES     IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES  IN SCHEMA stage, silver, gold TO sys_data_engineer;
GRANT SELECT ON ALL TABLES             IN SCHEMA dw TO sys_data_engineer;

-- BI ANALYST
GRANT USAGE  ON SCHEMA gold, dw TO sys_bi_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA gold, dw TO sys_bi_analyst;

-- BACKEND DEVELOPER
GRANT USAGE ON SCHEMA stage, silver, gold, dw TO sys_backend_developer;
GRANT ALL PRIVILEGES ON ALL TABLES     IN SCHEMA stage, silver, gold, dw TO sys_backend_developer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES  IN SCHEMA stage, silver, gold, dw TO sys_backend_developer;

-- DEVOPS (acesso total ao banco, precisa enxergar todos os schemas)
GRANT USAGE ON SCHEMA stage, silver, gold, dw TO sys_devops;

-- DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES IN SCHEMA stage, silver, gold
    GRANT ALL ON TABLES TO sys_data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA stage, silver, gold
    GRANT ALL ON SEQUENCES TO sys_data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA dw
    GRANT SELECT ON TABLES TO sys_data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA gold, dw
    GRANT SELECT ON TABLES TO sys_bi_analyst;
ALTER DEFAULT PRIVILEGES IN SCHEMA stage, silver, gold, dw
    GRANT ALL ON TABLES TO sys_backend_developer;
ALTER DEFAULT PRIVILEGES IN SCHEMA stage, silver, gold, dw
    GRANT ALL ON SEQUENCES TO sys_backend_developer;
