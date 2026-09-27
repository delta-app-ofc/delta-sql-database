# EXPLAIN ANALYZE — depois dos índices da camada de BI

Mesmo Postgres 18 descartável, mesmo dataload, agora **com** os índices recriados
(`datamart/stage/indexes.sql` + `datamart/gold/indexes.sql`) e `ANALYZE` rodado nas tabelas.

## 1. `stage.consumption_reading_raw` — `idx_consumption_reading_raw_property_date (property_id, read_at DESC)`

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM stage.consumption_reading_raw
WHERE property_id = 154 AND read_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY read_at DESC;
```

```
Sort  (cost=334.18..335.86 rows=672 width=40) (actual time=0.286..0.312 rows=672.00 loops=1)
  Buffers: shared hit=36 read=4
  ->  Bitmap Heap Scan on consumption_reading_raw  (cost=19.18..302.62 rows=672 width=40) (actual time=0.091..0.198 rows=672.00 loops=1)
        Recheck Cond: ((property_id = 154) AND (read_at >= (CURRENT_DATE - '7 days'::interval)))
        Heap Blocks: exact=33
        Buffers: shared hit=33 read=4
        ->  Bitmap Index Scan on idx_consumption_reading_raw_property_date  (cost=0.00..19.01 rows=672 width=0) (actual time=0.077..0.077 rows=672.00 loops=1)
              Index Cond: ((property_id = 154) AND (read_at >= (CURRENT_DATE - '7 days'::interval)))
Execution Time: 0.381 ms
```

**`Seq Scan` → `Bitmap Index Scan`**, buffers lidos 273 → 40 (~7x menos), tempo de execução 2,9 ms → 0,38 ms
(~7,7x mais rápido). Ganho real e mensurável — essa é a consulta que sustenta a tela de Monitoramento do
protótipo (últimos N dias de uma instalação), e é a tabela com o maior volume desta carga (28.800 linhas).

## 2. `gold.fact_consumption_daily` — `idx_gold_fact_consumption_daily_property_date (property_key, date_key)`

```
Sort  (cost=13.46..13.61 rows=60 width=36) (actual time=0.067..0.088 rows=60.00 loops=1)
  ->  Seq Scan on fact_consumption_daily  (cost=0.00..6.75 rows=60 width=36) (actual time=0.030..0.050 rows=60.00 loops=1)
        Filter: (property_key = (InitPlan 1).col1)
        Rows Removed by Filter: 240
Execution Time: 0.134 ms
```

## Nota sobre volume (por que o índice do `gold` não muda o plano nesta carga)

O planner **continua escolhendo `Seq Scan`** em `gold.fact_consumption_daily` mesmo com o índice criado —
e está certo em escolher isso: a tabela tem só 300 linhas (5 instalações × 60 dias de dado sintético), então
varrer a tabela inteira é mais barato que ler o índice e depois buscar cada linha na tabela (o mesmo raciocínio
vale pro índice em `dim_property`, com 155 linhas). Isso é o comportamento esperado do otimizador, não um
índice quebrado — um data mart acadêmico com semanas de dado sintético não tem volume suficiente pra um fato
diário mudar de plano. O índice foi criado mesmo assim porque:

1. Documenta a intenção de acesso (instalação + data é o padrão de consulta real da `dw.vw_consumption_daily`).
2. Passa a valer sozinho quando o volume crescer (ex.: quando a extração real do Mongo substituir o `stage`
   sintético por leituras de produção contínuas — ver pendência no `TASK.md`).

A evidência de ganho real desta rodada está na tabela de maior volume (`stage.consumption_reading_raw`,
seção 1), que é justamente o cenário que o índice foi desenhado para atender.
