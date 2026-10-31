# Delta Database
Repositório para armazenar os DDLs das tabelas do banco de dados do Projeto Delta

Consulte [DOCKER-HELP.md](DOCKER-HELP.md) para usar o ambiente Docker local.

## Testes de integração

Os testes executam os scripts SQL em um PostgreSQL 16 descartável. A suite verifica a criação do schema, constraints e o comportamento das funções de autorização e contexto organizacional com dados mínimos revertidos ao final.

```bash
docker compose --env-file docker-compose.test.env -p delta-sql-audit-test -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from smoke
docker compose --env-file docker-compose.test.env -p delta-sql-audit-test -f docker-compose.test.yml down
```

Esses testes SQL são evidência comportamental; não geram percentual de cobertura de linhas SQL.
