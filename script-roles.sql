-- 1. ROLES DO SISTEMA
    CREATE ROLE sys_engenheiro_dados       NOINHERIT;
    CREATE ROLE sys_desenvolvedor_backend  NOINHERIT;
    CREATE ROLE sys_analista_bi            NOINHERIT;
    CREATE ROLE sys_devops                 NOINHERIT;
    CREATE ROLE sys_primeiro_ano           NOINHERIT;

-- 2. USUÁRIOS
    CREATE USER samuel         WITH PASSWORD 'ALTERAR_SENHA_SAMUEL';
    CREATE USER mariana        WITH PASSWORD 'ALTERAR_SENHA_MARIANA';
    CREATE USER davi           WITH PASSWORD 'ALTERAR_SENHA_DAVI';
    CREATE USER joao           WITH PASSWORD 'ALTERAR_SENHA_JOAO';
    CREATE USER ana            WITH PASSWORD 'ALTERAR_SENHA_ANA';
    CREATE USER rahquel        WITH PASSWORD 'ALTERAR_SENHA_RAHQUEL';
    CREATE USER primeiro_ano   WITH PASSWORD 'ALTERAR_SENHA_PRIMEIRO_ANO';

-- 3. ATRIBUIÇÃO DE ROLES
    GRANT sys_devops                 TO samuel;
    GRANT sys_engenheiro_dados       TO samuel;
    GRANT sys_analista_bi            TO samuel;

    GRANT sys_engenheiro_dados       TO mariana;
    GRANT sys_desenvolvedor_backend  TO mariana;

    GRANT sys_desenvolvedor_backend  TO davi;
    GRANT sys_desenvolvedor_backend  TO joao;
    GRANT sys_analista_bi            TO ana;
    GRANT sys_desenvolvedor_backend  TO rahquel;

    GRANT sys_primeiro_ano           TO primeiro_ano;

-- 4. BACKEND - CRUD COMPLETO
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
          tbl_usuario,
          tbl_instalacao,
          tbl_usuario_instalacao,
          tbl_dispositivo,
          tbl_meta_consumo,
          tbl_alerta,
          tbl_habito,
          tbl_usuario_habito,
          tbl_tarifa_agua
    TO sys_desenvolvedor_backend;

-- 5. ENGENHEIRO DE DADOS
    GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO sys_engenheiro_dados;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sys_engenheiro_dados;
    GRANT CREATE                         ON SCHEMA public TO sys_engenheiro_dados;

-- 6. ANALISTA DE BI
    GRANT USAGE  ON SCHEMA public TO sys_analista_bi;
    GRANT SELECT ON ALL TABLES   IN SCHEMA public TO sys_analista_bi;

-- 7. DEVOPS
    GRANT ALL PRIVILEGES ON DATABASE delta TO sys_devops;

-- 8. PRIMEIRO ANO
    GRANT USAGE  ON SCHEMA public TO sys_primeiro_ano;
    GRANT SELECT ON ALL TABLES   IN SCHEMA public TO sys_primeiro_ano;

    REVOKE INSERT, UPDATE, DELETE ON ALL TABLES    FROM sys_primeiro_ano;
    REVOKE EXECUTE               ON ALL FUNCTIONS  FROM sys_primeiro_ano;

-- 9. DEFAULT PRIVILEGES
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sys_desenvolvedor_backend;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT ALL ON TABLES TO sys_engenheiro_dados;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO sys_analista_bi;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO sys_primeiro_ano;