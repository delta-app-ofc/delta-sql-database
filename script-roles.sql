-- 1. SYSTEM ROLES
    CREATE ROLE sys_data_engineer         NOINHERIT;
    CREATE ROLE sys_backend_developer     NOINHERIT;
    CREATE ROLE sys_bi_analyst            NOINHERIT;
    CREATE ROLE sys_devops                NOINHERIT;
    CREATE ROLE sys_first_year            NOINHERIT;

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

-- 4. BACKEND - FULL CRUD
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
          tbl_user,
          tbl_installation,
          tbl_user_installation,
          tbl_device,
          tbl_consumption_goal,
          tbl_alert,
          tbl_habit,
          tbl_user_habit,
          tbl_water_tariff
    TO sys_backend_developer;

-- 5. DATA ENGINEER
    GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO sys_data_engineer;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sys_data_engineer;
    GRANT CREATE                         ON SCHEMA public TO sys_data_engineer;

-- 6. BI ANALYST
    GRANT USAGE  ON SCHEMA public TO sys_bi_analyst;
    GRANT SELECT ON ALL TABLES   IN SCHEMA public TO sys_bi_analyst;

-- 7. DEVOPS
    GRANT ALL PRIVILEGES ON DATABASE delta TO sys_devops;

-- 8. FIRST YEAR
    GRANT USAGE  ON SCHEMA public TO sys_first_year;
    GRANT SELECT ON ALL TABLES   IN SCHEMA public TO sys_first_year;

    REVOKE INSERT, UPDATE, DELETE ON ALL TABLES    FROM sys_first_year;
    REVOKE EXECUTE               ON ALL FUNCTIONS  FROM sys_first_year;

-- 9. DEFAULT PRIVILEGES
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sys_backend_developer;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT ALL ON TABLES TO sys_data_engineer;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO sys_bi_analyst;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO sys_first_year;