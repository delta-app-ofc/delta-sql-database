# EXPLAIN ANALYZE — depois dos índices da camada de BI

Mesmo Postgres 18 descartável, mesmo dataload, agora com `script-indexes.sql` aplicado e `ANALYZE` rodado.

## 1. `stage.consumption_reading_raw` — `idx_consumption_reading_raw_property_date (property_id, read_at DESC)`

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM stage.consumption_reading_raw
WHERE property_id = 154 AND read_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY read_at DESC;
```

```
Sort  (cost=334.18..335.86 rows=672 width=40) (actual time=0.332..0.368 rows=672.00 loops=1)
  Buffers: shared hit=36 read=4
  ->  Bitmap Heap Scan on consumption_reading_raw  (cost=19.18..302.62 rows=672 width=40) (actual time=0.105..0.211 rows=672.00 loops=1)
        Recheck Cond: ((property_id = 154) AND (read_at >= (CURRENT_DATE - '7 days'::interval)))
        Heap Blocks: exact=33
        Buffers: shared hit=33 read=4
        ->  Bitmap Index Scan on idx_consumption_reading_raw_property_date  (cost=0.00..19.01 rows=672 width=0) (actual time=0.086..0.087 rows=672.00 loops=1)
              Index Cond: ((property_id = 154) AND (read_at >= (CURRENT_DATE - '7 days'::interval)))
Execution Time: 0.442 ms
```

`Seq Scan` → `Bitmap Index Scan`, buffers lidos 273 → 40 (~7x menos), tempo de execução 4,2 ms → 0,44 ms
(~9,4x mais rápido). Ganho real e mensurável — essa é a consulta que sustenta a tela de Monitoramento do
protótipo (últimos N dias de uma instalação), na tabela com o maior volume desta carga (28.800 linhas).

## 2. `gold.ft_consumption_daily` e `gold.ft_water_bill_monthly` — sem índice dedicado (de propósito)

A primeira versão desta camada tinha `idx_gold_ft_consumption_daily_property_date (property_key,
date_key)` e `idx_gold_ft_water_bill_monthly_person_date (person_key, date_key)`. Testando, descobri que os
dois eram **redundantes**: `gold.ft_consumption_daily` já tem `UNIQUE (property_key, date_key)` e
`gold.ft_water_bill_monthly` já tem `UNIQUE (person_key, date_key)` — cada `UNIQUE` já cria um índice btree
com exatamente essas colunas, na mesma ordem. Um índice extra idêntico não ajuda em nada e só custa espaço
e escrita a mais em toda inserção. Removidos — `script-indexes.sql` só cria o índice que faz diferença real
(`stage`, seção 1) e o de `gold.dm_property.organization_name`, que não tinha nenhum índice cobrindo ele.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM gold.ft_consumption_daily
WHERE property_key = (SELECT property_key FROM gold.dm_property WHERE property_id = 154)
ORDER BY date_key;
```

```
Sort  (cost=13.46..13.61 rows=60 width=35) (actual time=0.100..0.104 rows=60.00 loops=1)
  ->  Seq Scan on ft_consumption_daily  (cost=0.00..6.75 rows=60 width=35) (actual time=0.041..0.073 rows=60.00 loops=1)
        Filter: (property_key = (InitPlan 1).col1)
        Rows Removed by Filter: 240
Execution Time: 0.159 ms
```

Mesmo com o índice do `UNIQUE` disponível, o planner escolhe `Seq Scan` — e está certo: a tabela tem só
300 linhas (5 instalações × 60 dias de dado sintético), então varrer a tabela inteira é mais barato que ler
o índice e buscar cada linha. Comportamento esperado do otimizador num data mart acadêmico com poucas
semanas de dado sintético, não um índice quebrado. Passa a valer sozinho quando o volume crescer (ex.:
quando a extração real do Mongo substituir o `stage` sintético por leituras de produção contínuas — ver
pendência no `TASK.md`).

A evidência de ganho real desta rodada está na tabela de maior volume (`stage.consumption_reading_raw`,
seção 1), que é justamente o cenário que o índice foi desenhado para atender.
