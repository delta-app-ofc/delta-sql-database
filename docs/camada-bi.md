# Camada de BI (Data Mart) — Projeto Delta

## 1. Arquitetura em 4 schemas

| Schema | Papel | Materialização | Quem alimenta |
|---|---|---|---|
| `stage` | Cópia bruta de fonte externa (Mongo), sem tratamento nenhum. Nome e campos iguais aos da coleção de origem. | Tabela | `bi_etl.py` (produção) / `datamart/stage/seed_consumption_summary.sql` (sintético, hoje) |
| `silver` | Dado tratado: tipado, deduplicado, já ligado ao cadastro (ex.: resolve `device_id` → `property_id`). Ainda no grão original, sem chave substituta. | Tabela | procedures `silver.sp_load_*` |
| `gold` | Modelo dimensional final — `dm_*` (dimensão) e `ft_*` (fato), com chave substituta. Star schema puro (sem braço snowflake). | Tabela | procedures `gold.sp_load_*` |
| `dw` | Só views (`dw.vw_*`) — a camada que a ferramenta de BI (Power BI, Metabase etc.) consulta. CTEs + window functions. | View | nada — é view, não guarda dado |

Fluxo: `Mongo (consumption_summary)` → `stage.consumption_summary` → `silver.ft_consumption_reading` →
`silver.ft_consumption_daily` → `gold.ft_consumption_daily` → `dw.vw_*`. Dado cadastral do próprio Postgres
(`tb_property`, `tb_user`, `tb_last_water_bill`) entra direto em `silver`, sem passar por `stage` (já chega
limpo).

## 2. Agendamento

`.github/workflows/bi-etl.yml`, `cron` diário (`0 3 * * *`) + `workflow_dispatch` manual. Roda `bi_etl.py`,
que:
1. Descobre a marca d'água (`MAX(window_started_at)` já carregado em `stage.consumption_summary`).
2. Busca no Mongo (`db_delta_telemetry.consumption_summary`) só documentos mais novos que essa marca.
3. Insere em `stage.consumption_summary` (dedup por `mongo_id`, o `_id` do documento Mongo).
4. Chama `CALL silver.sp_load(); CALL gold.sp_load();`.

Frequência diária (não a cada 6h como o backup) porque a camada de BI serve relatório/ranking, não
dashboard ao vivo — consumo em tempo real é responsabilidade do Mongo/Redis (`delta-handbook`), não desta
camada. **`bi_etl.py` nunca rodou contra um Mongo real** (sem credenciais nesta sessão) — só a parte
Postgres foi testada (com documentos forjados). Ver pendência P2 no `TASK.md`.

## 3. `stage` — tabelas

### `stage.consumption_summary`
Espelho exato da coleção `consumption_summary` do MongoDB (`db_delta_telemetry`) — mesmo nome, mesmos
campos (`device_id`, `user_id`, `window_started_at`, `window_finished_at`, `consumption_liters`,
`lpm_average`, `anomaly_detected`), mais `mongo_id` (o `_id` do Mongo, pra dedup) e `loaded_at` (auditoria
própria do Postgres). Hoje populada com dado **sintético** (`datamart/stage/seed_consumption_summary.sql`),
não extração real.

## 4. `silver` — tabelas e procedures

| Tabela | Grão | De onde vem | Procedure |
|---|---|---|---|
| `silver.ft_consumption_reading` | 1 leitura (~15 min) | `stage.consumption_summary`, resolvendo `device_id` → `property_id` via `tb_device` | `silver.sp_load_ft_consumption_reading()` |
| `silver.ft_consumption_daily` | instalação × dia | Rollup (`SUM`/`AVG`) de `silver.ft_consumption_reading` | `silver.sp_load_ft_consumption_daily()` |
| `silver.dm_property` | 1 instalação | `tb_property` + `tb_address` + `tb_organization` + `tb_property_operational_profile` | `silver.sp_load_dm_property()` |
| `silver.dm_person` | 1 pessoa | `tb_user` + `tb_user_organization` (só pra saber o perfil) | `silver.sp_load_dm_person()` |
| `silver.ft_water_bill` | pessoa × mês | `tb_last_water_bill` + `tb_user` | `silver.sp_load_ft_water_bill()` |

`silver.sp_load()` chama as 5 acima, na ordem (leitura → rollup diário → propriedade → pessoa → fatura).

## 5. `gold` — tabelas e procedures

| Tabela | Grão | Chave substituta | Procedure |
|---|---|---|---|
| `gold.dm_date` | 1 dia (2024-2028) | `date_key` (YYYYMMDD) | `gold.sp_load_dm_date()` |
| `gold.dm_property` | 1 instalação | `property_key` | `gold.sp_load_dm_property()` |
| `gold.dm_person` | 1 pessoa | `person_key` | `gold.sp_load_dm_person()` |
| `gold.ft_consumption_daily` | instalação × dia | `fact_key` | `gold.sp_load_ft_consumption_daily()` |
| `gold.ft_water_bill_monthly` | pessoa × mês | `fact_key` | `gold.sp_load_ft_water_bill_monthly()` |
| `gold.ft_investment_scenario` | 1 cenário CAPEX | `scenario_key` | `gold.sp_load_ft_investment_scenario()` |

`gold.sp_load()` chama as 6 acima, nessa ordem. As duas dimensões (`dm_property`, `dm_person`) fazem
`DELETE` de quem não existe mais no `silver` antes do `INSERT ... ON CONFLICT DO UPDATE` — evita linha
órfã no `gold` se uma instalação/pessoa for removida do cadastro.

## 6. `dw` — views

| View | Grão | Window function |
|---|---|---|
| `vw_consumption_daily` | instalação × dia | `SUM() OVER` (acumulado), `AVG() OVER` (média móvel 7d) |
| `vw_property_ranking` | 1 instalação | `RANK`, `DENSE_RANK`, `NTILE(4)`, `PERCENT_RANK` |
| `vw_monthly_variation` | instalação × mês | `LAG()` |
| `vw_consumption_distribution` | 1 leitura diária | `NTILE(5)`, `PERCENTILE_CONT` |
| `vw_capex_comparison` | 1 cenário | `RANK()` por payback |
| `vw_residential_efficiency_ranking` | pessoa × mês | `RANK`, `PERCENT_RANK` |
| `vw_audit_history_chain` | 1 evento de auditoria de `tb_region_rate` | CTE recursiva sobre `previous_log_id` |

Todas leem só do `gold` (exceto `vw_audit_history_chain`, que é uma view de auditoria sobre
`tb_log_region_rate`, no schema `public` — não é uma view dimensional).

## 7. Índices

`idx_stage_consumption_summary_device_window` (o único com ganho real medido — ver
`docs/explain_before.md`/`explain_after.md`) e `idx_gold_dm_property_organization`. Dois outros índices
foram removidos por serem redundantes com `UNIQUE` constraints já existentes nos fatos do `gold`.

## 8. O que fica fora (Mongo)

Alerta, vazamento, notificação, escalonamento, relatório agendado e chat — tudo isso é evento/config de
alto volume, responsabilidade do MongoDB (`db_delta_app`), não desta camada. Pendência registrada no
`TASK.md`, seção 6.
