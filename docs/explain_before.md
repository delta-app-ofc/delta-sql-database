# EXPLAIN ANALYZE — antes dos índices da camada de BI

Testado num Postgres 18 descartável (Docker), com o schema + dataload completo (incluindo o volume
sintético de 28.800 leituras em `stage.consumption_reading_raw`, ver `datamart/stage/seed_consumption_reading_raw.sql`)
e **sem** os índices da seção "Índices" do `TASK.md` (removidos com `DROP INDEX` só para este teste).

## 1. `stage.consumption_reading_raw` — filtro por instalação + janela de tempo

Consulta real da tela de Monitoramento (últimos 7 dias de uma instalação):

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM stage.consumption_reading_raw
WHERE property_id = 154 AND read_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY read_at DESC;
```

```
Sort  (cost=877.56..879.24 rows=672 width=40) (actual time=2.835..2.863 rows=672.00 loops=1)
  Sort Key: read_at DESC
  Sort Method: quicksort  Memory: 67kB
  Buffers: shared hit=273
  ->  Seq Scan on consumption_reading_raw  (cost=0.00..846.00 rows=672 width=40) (actual time=2.344..2.722 rows=672.00 loops=1)
        Filter: ((property_id = 154) AND (read_at >= (CURRENT_DATE - '7 days'::interval)))
        Rows Removed by Filter: 28128
        Buffers: shared hit=270
Planning Time: 0.304 ms
Execution Time: 2.917 ms
```

**`Seq Scan`, descartando 28.128 das 28.800 linhas da tabela** (só 672 interessam) — 270 buffers lidos,
2,9 ms de execução. Sem índice, toda leitura da tabela precisa ser varrida pra achar as 672 linhas certas.

## 2. `gold.fact_consumption_daily` — filtro por instalação

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM gold.fact_consumption_daily
WHERE property_key = (SELECT property_key FROM gold.dim_property WHERE property_id = 154)
ORDER BY date_key;
```

```
Sort  (cost=13.46..13.61 rows=60 width=36) (actual time=0.108..0.120 rows=60.00 loops=1)
  ->  Seq Scan on fact_consumption_daily  (cost=0.00..6.75 rows=60 width=36) (actual time=0.032..0.053 rows=60.00 loops=1)
        Filter: (property_key = (InitPlan 1).col1)
        Rows Removed by Filter: 240
Execution Time: 0.198 ms
```

`gold.fact_consumption_daily` só tem 300 linhas nesta carga (5 instalações × 60 dias) — ver seção
"Nota sobre volume" em `explain_after.md`.
