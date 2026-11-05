# Delta Database
Repositório para armazenar os DDLs das tabelas do banco de dados do Projeto Delta

Consulte [DOCKER-HELP.md](DOCKER-HELP.md) para usar o ambiente Docker local.

## Processo medalhão (stage → silver → gold → dw)

Toda métrica analítica da plataforma web vem de uma view `dw.vw_*`; o front e a API não recalculam indicadores nem leem agregados direto do Mongo. O ranking de eficiência é a exceção deliberada: continua vindo do Redis (`delta-redis-database`), alimentado por este banco após o ETL.

| Camada | Papel | Exemplos |
|---|---|---|
| `stage` | Espelho cru do Mongo, carregado pelo `bi_etl.py` | `consumption_summary`, `alerts_history`, `user_preferences`, `device_status` |
| `silver` | Dado tratado e resolvido contra o OLTP (`tb_device`, `tb_property`) | `ft_consumption_reading`, `ft_alert`, `dm_device_status` |
| `gold` | Modelo dimensional (chaves surrogate, `date_key`) | `ft_consumption_daily`, `ft_consumption_reading`, `dm_property` |
| `dw` | Views de serviço, leem **somente** `gold.*` | `vw_ft_property_monthly`, `vw_ft_organization_monthly_kpi`, `vw_ft_leak` |

### Como criar um indicador
1. Se o dado ainda não está no `gold`, traga-o: tabela em `stage` → procedure `silver.sp_load_*` → procedure `gold.sp_load_*`, e inclua as chamadas em `silver.sp_load()` / `gold.sp_load()`. Coletor novo no `bi_etl.py` quando a fonte for o Mongo.
2. Crie a view `dw.vw_ft_<nome>` em `datamart/dw/views/` **e** em `script-datamart.sql` (o script consolidado é o que roda no `setup_db.py`). Estilo: vírgula à frente, CTEs `staging_*`/`agg_*`.
3. Documente as colunas em `script-catalogo-datamart.sql` e a regra de negócio (limiares, fórmulas) em comentário acima da view.
4. Rode `python setup_db.py` em um Postgres 16 e confira com `SELECT` nas views.

### Atualização de um banco já existente
Para quem já tem as camadas criadas por uma versão anterior, execute manualmente `script-migration-indicadores.sql` (idempotente): cria `tb_property_goal`, `stage.device_status`, as tabelas/colunas novas de silver e gold, recria as procedures e as views `dw`. Depois execute `CALL silver.sp_load(); CALL gold.sp_load();`. O `script-datamart.sql` continua sendo o script de criação do zero; a migração é gerada a partir dele. Confira o banco alvo antes de aplicar a migração.

### Dados de demonstração
`script-dataload-swift.sql` completa a organização Swift (10 unidades, metas, dispositivos, ~3 meses de consumo, status de dispositivos e alertas) escrevendo no `stage` o que o ETL traria do Mongo, e roda `silver.sp_load()` / `gold.sp_load()`. É idempotente.

### Regras dos indicadores
- Cenários CAPEX: `dw.vw_ft_capex_comparison` exclui registros legados com nome `Simulação Dash`; `GET /delta/analytics/capex-comparison` limita os demais cenários às opções globais e às organizações vinculadas às unidades do usuário.
- Meta: `goal_pct = consumo do mês / tb_property_goal.monthly_target_liters * 100`; `OK` ≤ 85%, `ATENCAO` ≤ 100%, `CRITICO` > 100%, `SEM_META` sem meta.
- Economia estimada: litros a menos que o mês anterior, ao custo médio do m³ do mês; só em mês completo (`is_complete_month`).
- Projeção do mês: consumo atual + (consumo atual − mês anterior), nunca negativa.
- Metas: a meta mensal de cada unidade fica em `tb_property_goal` e é alterada por `PUT /delta/property/{id}/goal` (a API recarrega a dimensão de instalações para a view refletir na hora).
- Impacto por cenário (`vw_ft_investment_impact`): economia anual de água = consumo anual médio dos meses fechados × redução do cenário; 1 caminhão-pipa de referência = 10.000 L; 1 mês de uma família de 4 pessoas = 18.000 L (150 L/pessoa/dia × 30 dias, referência de consumo doméstico da Embasa; veja [pesquisa de cenários no handbook](https://github.com/delta-app-ofc/delta-handbook/blob/main/DADOS/SQL/pesquisa-cenarios-investimento.md)).
- Vazamento: alertas `vazamento_continuo`; `ATIVO` sem `resolved_at`; perda = soma das leituras durante o alerta.

Observação: `script-roles.sql` pressupõe que os schemas e as roles já existem e que o banco se chama `deltadb`; em um banco totalmente vazio crie-os antes (ou rode sem esse script) para testar localmente.

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
