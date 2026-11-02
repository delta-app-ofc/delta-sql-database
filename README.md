# Delta · Banco de Dados Relacional

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-356ce0?logo=postgresql&logoColor=white)
![PL/pgSQL](https://img.shields.io/badge/PL%2FpgSQL-functions%20e%20procedures-4c80ec)
![Data Mart](https://img.shields.io/badge/Data%20Mart-Star%20Schema-9dbdff)
![Auditoria](https://img.shields.io/badge/Auditoria-21%20tabelas-4aaf80)
![Python](https://img.shields.io/badge/Python-ETL%20e%20backup-3776ab?logo=python&logoColor=white)

O banco de dados que guarda a história de cada gota. Aqui ficam os scripts SQL do PostgreSQL do **Projeto Delta**, a plataforma que monitora o consumo residencial e comercial de água com sensores conectados a hidrômetros. O banco organiza quem são as pessoas, onde estão os imóveis, quanto custa o metro cúbico de cada região e o que cada alteração mudou, e ainda alimenta a camada de BI.

**Tags:** `postgresql` · `plpgsql` · `normalizacao-3fn` · `data-mart` · `star-schema` · `window-functions` · `cte-recursiva` · `triggers-de-auditoria` · `backup` · `dau` · `etl` · `iot` · `agua`

## Sumário

- [Visão geral](#visão-geral)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Como montar o banco](#como-montar-o-banco)
- [Requisitos de Modelagem de Dados (MOD-01 a MOD-16)](#requisitos-de-modelagem-de-dados-mod-01-a-mod-16)
- [Testes de integração](#testes-de-integração)
- [Testes offline do ETL Python](#testes-offline-do-etl-python)
- [Repositórios relacionados](#repositórios-relacionados)

## Visão geral

| Camada | O que contém |
|---|---|
| Banco relacional | 22 tabelas de negócio e 4 técnicas, normalizadas até a 3FN, com PKs, FKs e restrições `CHECK` e `UNIQUE` |
| Regras de negócio | 24 Functions e 5 Procedures em PL/pgSQL |
| Auditoria | 21 tabelas `tb_log_*`, com triggers que registram `TG_OP`, `OLD`, `NEW` e `CURRENT_USER` |
| Data Mart | Schemas `stage`, `silver`, `gold` e `dw`, com Star Schema e nove views analíticas |
| Governança | Catálogo `tb_data_catalog` com 268 colunas e roles `sys_*` |
| Operação | Backup a cada 6 horas, ETL do MongoDB e testes de integração no CI |

A arquitetura completa, do sensor ao relatório de BI, está na [modelagem conceitual](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/anexos/modelagem-conceitual.png).

## Estrutura do repositório

| Caminho | Conteúdo |
|---|---|
| `tables/` | Definição individual de cada tabela |
| `functions/` e `procedures/` | Functions e Procedures de regras de negócio |
| `audit-tables/`, `audit-functions/` e `triggers/` | Tabelas de log, Functions de auditoria e triggers |
| `datamart/` | Schemas `stage`, `silver`, `gold` e `dw`, com tabelas, procedures, índices e views |
| `script-schema.sql` | Criação das tabelas na ordem de dependência |
| `script-optimization.sql` | Agregação das Functions e Procedures |
| `script-audit.sql` | Tabelas, Functions e triggers de auditoria |
| `script-roles.sql` | Roles, usuários e privilégios |
| `script-dataload.sql` | Carga de dados de teste (2.331 registros em 22 tabelas) |
| `script-catalogo-dados.sql` e `script-catalogo-datamart.sql` | Catálogo de metadados |
| `script-comments.sql` | `COMMENT ON COLUMN` gerado a partir do catálogo |
| `script-datamart.sql`, `script-indexes.sql` e `script-datamart-dataload.sql` | Data Mart, índices e carga do Data Mart |
| `bi_etl.py` | Extração incremental da telemetria do MongoDB para o Data Mart |
| `backup_db.py` | Backup com `pg_dump` e teste de restauração |
| `setup_db.py` | Executa todos os scripts na ordem correta |
| `tests/` | Testes de integração SQL e testes do ETL |
| `.github/workflows/` | Backup, ETL, testes e análise de qualidade |

## Como montar o banco

A ordem de execução dos scripts é fixa, e o `setup_db.py` já a segue:

1. `script-schema.sql`
2. `script-optimization.sql`
3. `script-audit.sql`
4. `script-roles.sql`
5. `script-dataload.sql`
6. `script-catalogo-dados.sql`
7. `script-comments.sql`
8. `script-datamart.sql`
9. `script-indexes.sql`
10. `script-datamart-dataload.sql`
11. `script-catalogo-datamart.sql`

Consulte [DOCKER-HELP.md](DOCKER-HELP.md) para usar o ambiente Docker local.

## Requisitos de Modelagem de Dados (MOD-01 a MOD-16)

Cada requisito tem uma justificativa própria no handbook e uma evidência neste repositório. O texto consolidado da entrega está em [entrega-modelagem-dados.md](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/entrega-modelagem-dados.md).

| Requisito | Evidência neste repositório | Justificativa |
|---|---|---|
| MOD-01 Banco normalizado até 3FN | [script-schema.sql](script-schema.sql) | [mod-01](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-01-banco-postgresql-normalizacao.md) |
| MOD-02 PKs, FKs e cardinalidades | [script-schema.sql](script-schema.sql) | [mod-02](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-02-pk-fk-cardinalidades.md) |
| MOD-03 Carga de 500 ou mais registros | [script-dataload.sql](script-dataload.sql) | [mod-03](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-03-carga-registros-verossimeis.md) |
| MOD-04 RPA de migração do legado | [delta-rpa](https://github.com/delta-app-ofc/delta-rpa) | [mod-04](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-04-rpa-migracao-banco-legado.md) |
| MOD-05 Views analíticas e Data Mart | [script-datamart.sql](script-datamart.sql) e [datamart/](datamart) | [mod-05](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-05-views-analiticas-data-mart.md) |
| MOD-06 CTEs no ETL | [sp_load_ft_consumption_daily.sql](datamart/silver/procedures/sp_load_ft_consumption_daily.sql) | [mod-06](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-06-ctes-etl-sql.md) |
| MOD-07 Window Functions | [datamart/dw/views](datamart/dw/views) | [mod-07](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-07-window-functions.md) |
| MOD-08 Functions de regras de negócio | [functions/](functions) | [mod-08](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-08-functions-regras-negocio.md) |
| MOD-09 Procedures de regras de negócio | [procedures/](procedures) | [mod-09](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-09-procedures-regras-negocio.md) |
| MOD-10 Triggers de auditoria | [script-audit.sql](script-audit.sql) | [mod-10](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-10-triggers-auditoria.md) |
| MOD-11 EXPLAIN ANALYZE e índices | [script-indexes.sql](script-indexes.sql) | [mod-11](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-11-explain-analyze-indices.md) |
| MOD-12 Catálogo de metadados | [tb_data_catalog.sql](tables/tb_data_catalog.sql) e [script-catalogo-dados.sql](script-catalogo-dados.sql) | [mod-12](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-12-catalogo-metadados.md) |
| MOD-13 Backup e recuperação | [backup_db.py](backup_db.py) e [backup-postgres.yml](.github/workflows/backup-postgres.yml) | [mod-13](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-13-backup-recuperacao.md) |
| MOD-14 DAU no PostgreSQL | [sp_register_user_access.sql](procedures/sp_register_user_access.sql) e [fn_get_dau.sql](functions/fn_get_dau.sql) | [mod-14](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-14-dau-daily-active-user.md) |
| MOD-15 CTE recursiva | [vw_audit_history_chain.sql](datamart/dw/views/vw_audit_history_chain.sql) | [mod-15](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-15-cte-recursiva-heranca.md) |
| MOD-16 Relatório de justificativas | Este README | [mod-16](https://github.com/delta-app-ofc/delta-handbook/blob/docs/explicacao-requisitos/DADOS/SQL/documenta%C3%A7%C3%A3o-requisitos/mod-16-relatorio-justificativas.md) |

## Testes de integração

Os testes executam os scripts SQL em um PostgreSQL 16 descartável. A suíte verifica a criação do schema, constraints e o comportamento das funções de autorização e contexto organizacional com dados mínimos revertidos ao final.

```bash
docker compose --env-file docker-compose.test.env -p delta-sql-audit-test -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from smoke
docker compose --env-file docker-compose.test.env -p delta-sql-audit-test -f docker-compose.test.yml down
```

Esses testes SQL são evidência comportamental; não geram percentual de cobertura de linhas SQL.

## Testes offline do ETL Python

O arquivo `bi_etl.py` também possui suíte offline com adaptadores simulados. Instale `requirements.txt` e `requirements-dev.txt`, crie `reports/` e execute:

```powershell
python -m coverage run --branch --source=bi_etl -m pytest -q tests/test_bi_etl.py --junitxml=reports/junit.xml
python -m coverage xml -o reports/coverage.xml
```

O Sonar mede o ETL Python; os scripts `script-schema.sql`, `script-optimization.sql` e `script-audit.sql` continuam validados pelo smoke e isolamento PostgreSQL, sem percentual de linhas SQL. Os testes offline não acessam bancos reais nem alteram o workflow de ETL e deploy.

## Repositórios relacionados

- [delta-handbook](https://github.com/delta-app-ofc/delta-handbook/tree/docs/explicacao-requisitos/DADOS): documentação técnica de dados, com a justificativa de cada requisito.
- [delta-rpa](https://github.com/delta-app-ofc/delta-rpa): RPA que migra o banco legado para este banco normalizado.
