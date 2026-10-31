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

## Testes offline do ETL Python

O arquivo bi_etl.py tambem possui suite offline com adaptadores simulados. Instale requirements.txt e requirements-dev.txt, crie reports/ e execute:

```powershell
python -m coverage run --branch --source=bi_etl -m pytest -q tests/test_bi_etl.py --junitxml=reports/junit.xml
python -m coverage xml -o reports/coverage.xml
```

O Sonar mede o ETL Python; os arquivos SQL continuam validados pelo smoke e isolamento PostgreSQL, sem percentual de linhas SQL. Os checks de ETL e integracao devem ser obrigatorios na main. Os testes offline nao acessam bancos reais nem alteram o workflow de ETL/deploy.
