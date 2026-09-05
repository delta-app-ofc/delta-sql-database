-- 1. SYSTEM ROLES
    CREATE ROLE sys_data_engineer;
    CREATE ROLE sys_backend_developer;
    CREATE ROLE sys_bi_analyst;
    CREATE ROLE sys_devops;
    CREATE ROLE sys_first_year;

-- 2. USERS
    CREATE USER samuel         WITH PASSWORD 'CHANGE_PASSWORD_SAMUEL';
    CREATE USER mariana        WITH PASSWORD 'CHANGE_PASSWORD_MARIANA';
    CREATE USER davi           WITH PASSWORD 'CHANGE_PASSWORD_DAVI';
    CREATE USER joao           WITH PASSWORD 'CHANGE_PASSWORD_JOAO';
    CREATE USER ana            WITH PASSWORD 'CHANGE_PASSWORD_ANA';
    CREATE USER rahquel        WITH PASSWORD 'CHANGE_PASSWORD_RAHQUEL';
    CREATE USER first_year     WITH PASSWORD 'CHANGE_PASSWORD_FIRST_YEAR';

-- 3. ROLE ASSIGNMENTS
    GRANT sys_devops                TO samuel;
    GRANT sys_data_engineer         TO samuel;
    GRANT sys_bi_analyst            TO samuel;
    GRANT sys_data_engineer         TO mariana;
    GRANT sys_backend_developer     TO mariana;
    GRANT sys_backend_developer     TO davi;
    GRANT sys_backend_developer     TO joao;
    GRANT sys_bi_analyst            TO ana;
    GRANT sys_backend_developer     TO rahquel;
    GRANT sys_first_year            TO first_year;

-- 4. BACKEND
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
          tb_region,
          tb_day_of_week,
          tb_habit,
          tb_address,
          tb_user,
          tb_property,
          tb_user_property,
          tb_device,
          tb_region_rate,
          tb_user_habit,
          tb_user_habit_day,
          tb_last_water_bill,
          tb_log_rpa
    TO sys_backend_developer;

    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO sys_backend_developer;

-- 5. DATA ENGINEER
    GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO sys_data_engineer;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sys_data_engineer;
    GRANT CREATE                         ON SCHEMA public TO sys_data_engineer;

-- 6. BI ANALYST
    GRANT USAGE  ON SCHEMA public TO sys_bi_analyst;
    GRANT SELECT ON ALL TABLES   IN SCHEMA public TO sys_bi_analyst;

-- 7. DEVOPS
    GRANT ALL PRIVILEGES ON DATABASE deltadb TO sys_devops;

-- 8. FIRST YEAR
    GRANT USAGE  ON SCHEMA public TO sys_first_year;
    GRANT SELECT ON ALL TABLES   IN SCHEMA public TO sys_first_year;
    REVOKE INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA public FROM sys_first_year;
    REVOKE EXECUTE               ON ALL FUNCTIONS  IN SCHEMA public FROM sys_first_year;

-- 9. DEFAULT PRIVILEGES
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sys_backend_developer;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT USAGE, SELECT ON SEQUENCES TO sys_backend_developer;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT ALL ON TABLES TO sys_data_engineer;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT ALL ON SEQUENCES TO sys_data_engineer;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO sys_bi_analyst;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO sys_first_year;