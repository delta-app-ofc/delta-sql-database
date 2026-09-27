-- Consolida a camada de BI (Data Mart): stage -> silver -> gold -> dw.
-- Concatenacao dos arquivos em datamart/*, na ordem de dependencia -
-- mesma convencao de script-schema.sql (fonte de verdade e cada arquivo
-- individual em datamart/, este script e so pra execucao). Roda depois de
-- script-schema.sql + script-optimization.sql + script-audit.sql +
-- script-dataload.sql (precisa das tabelas operacionais e de
-- fn_get_current_region_rate ja existirem).

-- Esquema STAGE: copia bruta, sem tratamento. Hoje so existe aqui o que
-- viria de uma fonte fora do Postgres (MongoDB) - dado cadastral do proprio
-- Postgres (ex.: tb_last_water_bill) e tratado direto no SILVER, sem passar
-- por aqui, porque ja chega limpo.
CREATE SCHEMA IF NOT EXISTS stage;

-- Formato pensado pra bater com o que uma extracao real da colecao
-- consumption_summary do MongoDB (db_delta_telemetry, ver
-- repo-docs/delta-handbook/DADOS/NoSQL/modelagem-mongodb.md) traria: volume
-- consumido numa janela de tempo, por dispositivo/instalacao. AQUI o dado E
-- SINTETICO (gerado via generate_series em datamart/stage/seed_consumption_reading_raw.sql)
-- porque nao existe integracao real com o Mongo ainda para o perfil
-- industrial - pendencia registrada no TASK.md. Nao usar em decisao de
-- negocio real, so pra sustentar o desenvolvimento/demonstracao da camada
-- de BI (star schema, indices, EXPLAIN ANALYZE).
CREATE TABLE stage.consumption_reading_raw (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
      CONSTRAINT chk_stage_consumption_reading_raw_volume_liters
        CHECK (volume_liters >= 0)
    , flow_lmin             NUMERIC(10,3) NOT NULL
      CONSTRAINT chk_stage_consumption_reading_raw_flow_lmin
        CHECK (flow_lmin >= 0)
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consumption_reading_raw_property_date
    ON stage.consumption_reading_raw (property_id, read_at DESC);

-- Esquema SILVER: dado tratado (tipado, deduplicado, conformado), ainda no
-- grao original (sem chave substituta - isso e trabalho do GOLD).
CREATE SCHEMA IF NOT EXISTS silver;

-- Copia tratada de stage.consumption_reading_raw: mesmo grao (leitura),
-- mas com unicidade garantida (property_id, read_at) - a fonte sintetica de
-- hoje nao duplica, mas uma extracao real do Mongo poderia reenviar a mesma
-- janela mais de uma vez, e e aqui que isso e resolvido.
CREATE TABLE silver.consumption_reading (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , read_at               TIMESTAMP     NOT NULL
    , volume_liters         NUMERIC(10,3) NOT NULL
    , flow_lmin             NUMERIC(10,3) NOT NULL
    , CONSTRAINT uq_silver_consumption_reading_property_read_at
        UNIQUE (property_id, read_at)
);

-- Rollup diario de silver.consumption_reading - grao instalacao x dia.
CREATE TABLE silver.consumption_daily (
      id                    BIGSERIAL     PRIMARY KEY
    , property_id           INTEGER       NOT NULL
    , consumption_day       DATE          NOT NULL
    , total_liters          NUMERIC(12,3) NOT NULL
    , avg_flow_lmin         NUMERIC(10,3) NOT NULL
    , CONSTRAINT uq_silver_consumption_daily_property_day
        UNIQUE (property_id, consumption_day)
);

-- Copia tratada de tb_property, ja com o join de tb_address/tb_organization/
-- tb_property_operational_profile resolvido (dado cadastral do proprio
-- Postgres, ja limpo - nao passa por stage). Ainda na chave natural
-- (property_id) - o GOLD e quem monta a chave substituta do star schema.
CREATE TABLE silver.property (
      property_id           INTEGER       PRIMARY KEY
    , name                  VARCHAR(100)  NOT NULL
    , property_type         VARCHAR(20)   NOT NULL
    , classification_id     INTEGER       NOT NULL
    , classification_group  VARCHAR(20)   NOT NULL
    , region_id             INTEGER       NOT NULL
    , city                  VARCHAR(60)   NOT NULL
    , state                 VARCHAR(30)   NOT NULL
    , built_area_m2         NUMERIC(10,2)
    , organization_id       INTEGER
    , organization_name     VARCHAR(150)
    , has_operational_profile BOOLEAN     NOT NULL DEFAULT FALSE
    , shift_count           SMALLINT
    , main_water_source     VARCHAR(20)
);

-- Unifica tb_user pros dois perfis de uso (residencial e gestor industrial),
-- sem papel/hierarquia entre eles - so marca se a pessoa tem vinculo com
-- alguma organizacao (tb_user_organization) ou nao.
CREATE TABLE silver.person (
      user_id               INTEGER     PRIMARY KEY
    , name                  VARCHAR(100) NOT NULL
    , profile_type          VARCHAR(20) NOT NULL
      CONSTRAINT chk_silver_person_profile_type
        CHECK (profile_type IN ('RESIDENCIAL', 'GESTOR'))
);

-- Copia tratada de tb_last_water_bill + tb_user - dado real, sem sintetico,
-- cobre o perfil residencial na camada de BI.
CREATE TABLE silver.water_bill (
      id                    BIGSERIAL     PRIMARY KEY
    , user_id               INTEGER       NOT NULL
    , user_name             VARCHAR(100)  NOT NULL
    , bill_month            DATE          NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
    , m3_value              NUMERIC(10,2) NOT NULL
    , CONSTRAINT uq_silver_water_bill_user_month
        UNIQUE (user_id, bill_month)
);

-- Carga do SILVER, idempotente: pode ser chamada de novo a qualquer momento
-- (ex.: agendada via GitHub Actions - ver TASK.md) sem duplicar linha nem
-- perder dado. Le de stage (industrial, sintetico por ora) e direto das
-- tabelas cadastrais do proprio Postgres (residencial, dado real).
CREATE OR REPLACE PROCEDURE silver.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    -- 1) leituras industriais: so insere o que ainda nao existe (grao fino,
    -- nao muda depois de gravado).
    INSERT INTO silver.consumption_reading (property_id, read_at, volume_liters, flow_lmin)
    SELECT r.property_id, r.read_at, r.volume_liters, r.flow_lmin
    FROM stage.consumption_reading_raw r
    ON CONFLICT (property_id, read_at) DO NOTHING;

    -- 2) rollup diario (CTE de agregacao - a "transformacao" de verdade
    -- desta camada): soma litros e vazao media por instalacao x dia.
    WITH daily AS (
        SELECT
              property_id
            , DATE(read_at)                AS consumption_day
            , SUM(volume_liters)            AS total_liters
            , AVG(flow_lmin)                AS avg_flow_lmin
        FROM silver.consumption_reading
        GROUP BY property_id, DATE(read_at)
    )
    INSERT INTO silver.consumption_daily (property_id, consumption_day, total_liters, avg_flow_lmin)
    SELECT property_id, consumption_day, total_liters, avg_flow_lmin
    FROM daily
    ON CONFLICT (property_id, consumption_day) DO UPDATE
        SET total_liters  = EXCLUDED.total_liters
          , avg_flow_lmin = EXCLUDED.avg_flow_lmin;

    -- 3) instalacoes (residencial + industrial): dado cadastral do proprio
    -- Postgres, ja limpo - refresh completo porque e "estado atual", nao
    -- historico.
    TRUNCATE TABLE silver.property;

    INSERT INTO silver.property
    (
          property_id, name, property_type, classification_id, classification_group
        , region_id, city, state, built_area_m2
        , organization_id, organization_name
        , has_operational_profile, shift_count, main_water_source
    )
    SELECT
          p.id
        , p.name
        , p.type
        , p.classification_id
        , pc.group_name
        , a.region_id
        , a.city
        , a.state
        , p.built_area_m2
        , p.organization_id
        , o.trade_name
        , (op.property_id IS NOT NULL)
        , op.shift_count
        , op.main_water_source
    FROM tb_property p
    JOIN tb_property_classification pc ON pc.id = p.classification_id
    JOIN tb_address a                  ON a.id = p.address_id
    LEFT JOIN tb_organization o        ON o.id = p.organization_id
    LEFT JOIN tb_property_operational_profile op ON op.property_id = p.id;

    -- 4) pessoas (residencial + gestor): dado cadastral, refresh completo.
    TRUNCATE TABLE silver.person;

    INSERT INTO silver.person (user_id, name, profile_type)
    SELECT
          u.id
        , u.name
        , CASE WHEN uo.user_id IS NOT NULL THEN 'GESTOR' ELSE 'RESIDENCIAL' END
    FROM tb_user u
    LEFT JOIN (SELECT DISTINCT user_id FROM tb_user_organization) uo ON uo.user_id = u.id;

    -- 5) faturas residenciais: dado real, append-safe (fatura ja lancada nao
    -- muda, mas usa upsert por seguranca em reprocessamento).
    INSERT INTO silver.water_bill (user_id, user_name, bill_month, total_value, m3_value)
    SELECT b.user_id, u.name, b.month, b.total_value, b.m3_value
    FROM tb_last_water_bill b
    JOIN tb_user u ON u.id = b.user_id
    ON CONFLICT (user_id, bill_month) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value     = EXCLUDED.m3_value;

END;
$$;

-- Esquema GOLD: tabelas finais, sem tratamento pendente - modelo
-- dimensional (dim_*/fact_*), chave substituta, star schema puro (sem braco
-- snowflake: organizacao fica denormalizada dentro de dim_property).
CREATE SCHEMA IF NOT EXISTS gold;

-- Grao: 1 dia. Gerada via generate_series (gold.sp_load()), nao depende de
-- tabela de calendario externa.
CREATE TABLE gold.dim_date (
      date_key              INTEGER     PRIMARY KEY
    , full_date             DATE        NOT NULL UNIQUE
    , day_of_week           SMALLINT    NOT NULL
    , day_name              VARCHAR(20) NOT NULL
    , week_of_year          SMALLINT    NOT NULL
    , month_number          SMALLINT    NOT NULL
    , quarter_number        SMALLINT    NOT NULL
    , year_number           SMALLINT    NOT NULL
    , is_weekend            BOOLEAN     NOT NULL
);

-- Grao: 1 instalacao (residencial ou industrial). Star schema puro: dados
-- de organizacao ficam denormalizados aqui em vez de virar um braco
-- snowflake separado (dim_organization).
CREATE TABLE gold.dim_property (
      property_key            SERIAL      PRIMARY KEY
    , property_id             INTEGER     NOT NULL UNIQUE
    , name                    VARCHAR(100) NOT NULL
    , property_type           VARCHAR(20) NOT NULL
    , classification_group    VARCHAR(20) NOT NULL
    , city                    VARCHAR(60) NOT NULL
    , state                   VARCHAR(30) NOT NULL
    , built_area_m2           NUMERIC(10,2)
    , organization_name       VARCHAR(150)
    , has_operational_profile BOOLEAN     NOT NULL
);

-- Grao: 1 pessoa (tb_user), unificando os dois perfis de uso.
CREATE TABLE gold.dim_person (
      person_key            SERIAL      PRIMARY KEY
    , user_id               INTEGER     NOT NULL UNIQUE
    , name                  VARCHAR(100) NOT NULL
    , profile_type          VARCHAR(20) NOT NULL
);

-- Grao: instalacao x dia (industrial). Custo resolvido via
-- fn_get_current_region_rate (reaproveita a funcao existente, nao duplica a
-- logica de tarifa vigente).
CREATE TABLE gold.fact_consumption_daily (
      fact_key              BIGSERIAL     PRIMARY KEY
    , property_key          INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , total_liters          NUMERIC(12,3) NOT NULL
    , avg_flow_lmin         NUMERIC(10,3) NOT NULL
    , cost_value            NUMERIC(12,2) NOT NULL
    , CONSTRAINT uq_gold_fact_consumption_daily_property_date
        UNIQUE (property_key, date_key)
    , CONSTRAINT fk_gold_fact_consumption_daily_property
        FOREIGN KEY (property_key) REFERENCES gold.dim_property (property_key)
    , CONSTRAINT fk_gold_fact_consumption_daily_date
        FOREIGN KEY (date_key) REFERENCES gold.dim_date (date_key)
);

-- Grao: pessoa x mes (residencial). date_key aponta pro primeiro dia do mes
-- de referencia da fatura.
CREATE TABLE gold.fact_water_bill_monthly (
      fact_key              BIGSERIAL     PRIMARY KEY
    , person_key            INTEGER       NOT NULL
    , date_key              INTEGER       NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
    , m3_value              NUMERIC(10,2) NOT NULL
    , CONSTRAINT uq_gold_fact_water_bill_monthly_person_date
        UNIQUE (person_key, date_key)
    , CONSTRAINT fk_gold_fact_water_bill_monthly_person
        FOREIGN KEY (person_key) REFERENCES gold.dim_person (person_key)
    , CONSTRAINT fk_gold_fact_water_bill_monthly_date
        FOREIGN KEY (date_key) REFERENCES gold.dim_date (date_key)
);

-- Grao: 1 cenario de investimento (referencia, sem grao de tempo/instalacao
-- proprio - alimenta so a comparacao de cenarios do CAPEX).
CREATE TABLE gold.fact_investment_scenario (
      scenario_key          SERIAL        PRIMARY KEY
    , scenario_id           INTEGER       NOT NULL UNIQUE
    , name                  VARCHAR(100)  NOT NULL
    , investment_value      NUMERIC(10,2) NOT NULL
    , reduction_pct         NUMERIC(5,2)  NOT NULL
    , annual_savings_value  NUMERIC(10,2) NOT NULL
    , payback_months        NUMERIC(6,1)
);

-- Carga do GOLD, idempotente: monta o modelo dimensional (chave substituta)
-- a partir do SILVER. Chamada depois de silver.sp_load() (ver TASK.md /
-- workflow de agendamento).
CREATE OR REPLACE PROCEDURE gold.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    -- 1) dim_date: faixa fixa e larga o suficiente pra cobrir qualquer dado
    -- (sintetico de hoje ou real no futuro), gerada uma vez via
    -- generate_series - nao depende de tabela de calendario externa.
    INSERT INTO gold.dim_date (date_key, full_date, day_of_week, day_name, week_of_year, month_number, quarter_number, year_number, is_weekend)
    SELECT
          TO_CHAR(d, 'YYYYMMDD')::INTEGER
        , d
        , EXTRACT(DOW FROM d)
        , TRIM(TO_CHAR(d, 'Day'))
        , EXTRACT(WEEK FROM d)
        , EXTRACT(MONTH FROM d)
        , EXTRACT(QUARTER FROM d)
        , EXTRACT(YEAR FROM d)
        , EXTRACT(DOW FROM d) IN (0, 6)
    FROM generate_series('2024-01-01'::DATE, '2028-12-31'::DATE, INTERVAL '1 day') AS d
    ON CONFLICT (date_key) DO NOTHING;

    -- 2) dim_property: upsert a partir do silver (star schema puro, sem
    -- braco snowflake pra organizacao).
    INSERT INTO gold.dim_property (property_id, name, property_type, classification_group, city, state, built_area_m2, organization_name, has_operational_profile)
    SELECT property_id, name, property_type, classification_group, city, state, built_area_m2, organization_name, has_operational_profile
    FROM silver.property
    ON CONFLICT (property_id) DO UPDATE
        SET name                     = EXCLUDED.name
          , property_type            = EXCLUDED.property_type
          , classification_group     = EXCLUDED.classification_group
          , city                     = EXCLUDED.city
          , state                    = EXCLUDED.state
          , built_area_m2            = EXCLUDED.built_area_m2
          , organization_name        = EXCLUDED.organization_name
          , has_operational_profile  = EXCLUDED.has_operational_profile;

    -- 3) dim_person: upsert a partir do silver.
    INSERT INTO gold.dim_person (user_id, name, profile_type)
    SELECT user_id, name, profile_type
    FROM silver.person
    ON CONFLICT (user_id) DO UPDATE
        SET name         = EXCLUDED.name
          , profile_type = EXCLUDED.profile_type;

    -- 4) fact_consumption_daily: CTE em etapas - resolve a chave substituta,
    -- resolve o custo chamando fn_get_current_region_rate (reaproveita a
    -- funcao existente em vez de recalcular tarifa).
    WITH staging_daily AS (
        SELECT
              cd.property_id
            , cd.consumption_day
            , cd.total_liters
            , cd.avg_flow_lmin
            , sp.region_id
            , sp.classification_id
        FROM silver.consumption_daily cd
        JOIN silver.property sp ON sp.property_id = cd.property_id
    ),
    with_cost AS (
        SELECT
              sd.*
            , ROUND(sd.total_liters / 1000.0 * fn_get_current_region_rate(sd.region_id, sd.classification_id, sd.consumption_day), 2) AS cost_value
        FROM staging_daily sd
    )
    INSERT INTO gold.fact_consumption_daily (property_key, date_key, total_liters, avg_flow_lmin, cost_value)
    SELECT
          dp.property_key
        , TO_CHAR(wc.consumption_day, 'YYYYMMDD')::INTEGER
        , wc.total_liters
        , wc.avg_flow_lmin
        , wc.cost_value
    FROM with_cost wc
    JOIN gold.dim_property dp ON dp.property_id = wc.property_id
    ON CONFLICT (property_key, date_key) DO UPDATE
        SET total_liters  = EXCLUDED.total_liters
          , avg_flow_lmin = EXCLUDED.avg_flow_lmin
          , cost_value    = EXCLUDED.cost_value;

    -- 5) fact_water_bill_monthly.
    INSERT INTO gold.fact_water_bill_monthly (person_key, date_key, total_value, m3_value)
    SELECT
          dp.person_key
        , TO_CHAR(wb.bill_month, 'YYYYMMDD')::INTEGER
        , wb.total_value
        , wb.m3_value
    FROM silver.water_bill wb
    JOIN gold.dim_person dp ON dp.user_id = wb.user_id
    ON CONFLICT (person_key, date_key) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value    = EXCLUDED.m3_value;

    -- 6) fact_investment_scenario: dado de referencia, ja limpo, sem join
    -- necessario - le direto de tb_investment_scenario (nao precisa passar
    -- por silver, nao ha tratamento nenhum a fazer aqui).
    INSERT INTO gold.fact_investment_scenario (scenario_id, name, investment_value, reduction_pct, annual_savings_value, payback_months)
    SELECT id, name, investment_value, reduction_pct, annual_savings_value, payback_months
    FROM tb_investment_scenario
    ON CONFLICT (scenario_id) DO UPDATE
        SET name                 = EXCLUDED.name
          , investment_value     = EXCLUDED.investment_value
          , reduction_pct        = EXCLUDED.reduction_pct
          , annual_savings_value = EXCLUDED.annual_savings_value
          , payback_months       = EXCLUDED.payback_months;

END;
$$;

CREATE INDEX idx_gold_fact_consumption_daily_property_date
    ON gold.fact_consumption_daily (property_key, date_key);

CREATE INDEX idx_gold_fact_water_bill_monthly_person_date
    ON gold.fact_water_bill_monthly (person_key, date_key);

CREATE INDEX idx_gold_dim_property_organization
    ON gold.dim_property (organization_name);

-- Esquema DW: so views (dw.vw_*) - a camada de consumo da BI, com CTEs +
-- window functions, lendo so do GOLD (exceto vw_audit_history_chain, que e
-- uma view de auditoria/governanca sobre tb_log_region_rate, nao uma view
-- dimensional - ver comentario nela).
CREATE SCHEMA IF NOT EXISTS dw;

-- Grao: instalacao x dia (industrial). Window functions: SUM() OVER pra
-- total acumulado no periodo e AVG() OVER pra media movel de 7 dias -
-- espelha o card de consumo acumulado do prototipo.
CREATE OR REPLACE VIEW dw.vw_consumption_daily AS
WITH staging_consumption AS (
    SELECT
          f.property_key
        , dp.property_id
        , dp.name           AS property_name
        , dd.full_date
        , f.total_liters
        , f.cost_value
    FROM gold.fact_consumption_daily f
    JOIN gold.dim_property dp ON dp.property_key = f.property_key
    JOIN gold.dim_date dd     ON dd.date_key = f.date_key
)
SELECT
      property_id
    , property_name
    , full_date
    , total_liters
    , cost_value
    , SUM(total_liters) OVER (
          PARTITION BY property_id ORDER BY full_date
          ROWS UNBOUNDED PRECEDING
      ) AS running_total_liters
    , AVG(total_liters) OVER (
          PARTITION BY property_id ORDER BY full_date
          ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ) AS moving_avg_7d_liters
FROM staging_consumption;

-- Grao: instalacao (industrial), agregada no periodo todo disponivel.
-- Window functions: RANK/DENSE_RANK/NTILE/PERCENT_RANK por L/m² - espelha a
-- tela "Ranking" do prototipo.
CREATE OR REPLACE VIEW dw.vw_property_ranking AS
WITH agg_consumption AS (
    SELECT
          dp.property_id
        , dp.name             AS property_name
        , dp.built_area_m2
        , SUM(f.total_liters) AS total_liters
        , SUM(f.cost_value)   AS total_cost
    FROM gold.fact_consumption_daily f
    JOIN gold.dim_property dp ON dp.property_key = f.property_key
    WHERE dp.built_area_m2 IS NOT NULL
    GROUP BY dp.property_id, dp.name, dp.built_area_m2
),
final_ranking AS (
    SELECT
          property_id
        , property_name
        , total_liters
        , total_cost
        , ROUND(total_liters / built_area_m2, 2) AS liters_per_m2
    FROM agg_consumption
)
SELECT
      property_id
    , property_name
    , total_liters
    , total_cost
    , liters_per_m2
    , RANK()         OVER (ORDER BY liters_per_m2 ASC)  AS rank_efficiency
    , DENSE_RANK()   OVER (ORDER BY total_cost DESC)    AS rank_cost
    , NTILE(4)       OVER (ORDER BY liters_per_m2)      AS consumption_quartile
    , PERCENT_RANK() OVER (ORDER BY liters_per_m2)      AS consumption_percent_rank
FROM final_ranking;

-- Grao: instalacao x mes (industrial). Window function: LAG() pra variacao
-- % mes a mes - espelha o "varMes" hoje estatico no prototipo.
CREATE OR REPLACE VIEW dw.vw_monthly_variation AS
WITH staging_monthly AS (
    SELECT
          dp.property_id
        , dp.name AS property_name
        , DATE_TRUNC('month', dd.full_date)::DATE AS reference_month
        , SUM(f.total_liters) AS total_liters
    FROM gold.fact_consumption_daily f
    JOIN gold.dim_property dp ON dp.property_key = f.property_key
    JOIN gold.dim_date dd     ON dd.date_key = f.date_key
    GROUP BY dp.property_id, dp.name, DATE_TRUNC('month', dd.full_date)
),
final_variation AS (
    SELECT
          property_id
        , property_name
        , reference_month
        , total_liters
        , LAG(total_liters) OVER (PARTITION BY property_id ORDER BY reference_month) AS previous_month_liters
    FROM staging_monthly
)
SELECT
      property_id
    , property_name
    , reference_month
    , total_liters
    , previous_month_liters
    , ROUND(
          (total_liters - previous_month_liters) / NULLIF(previous_month_liters, 0) * 100
        , 1
      ) AS variation_pct
FROM final_variation;

-- Grao: 1 linha (estatistica agregada sobre o consumo diario de todas as
-- instalacoes industriais). Window/agregacao: NTILE + PERCENTILE_CONT pra
-- min/Q1/mediana/Q3/max - substitui o histograma/boxplot hoje calculado em
-- JS no prototipo (renderBoxplot()).
CREATE OR REPLACE VIEW dw.vw_consumption_distribution AS
WITH staging_daily_totals AS (
    SELECT
          f.property_key
        , f.total_liters
    FROM gold.fact_consumption_daily f
),
agg_stats AS (
    SELECT
          MIN(total_liters) AS min_liters
        , MAX(total_liters) AS max_liters
        , PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_liters) AS q1_liters
        , PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_liters) AS median_liters
        , PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_liters) AS q3_liters
    FROM staging_daily_totals
)
SELECT
      s.property_key
    , s.total_liters
    , NTILE(5) OVER (ORDER BY s.total_liters) AS distribution_bucket
    , a.min_liters
    , a.q1_liters
    , a.median_liters
    , a.q3_liters
    , a.max_liters
FROM staging_daily_totals s
CROSS JOIN agg_stats a;

-- Grao: 1 cenario de investimento (CAPEX). Window function: RANK() por
-- payback - espelha o "Simulador de Investimento" do prototipo, agora com
-- valores pesquisados em vez de ficticios (ver tb_investment_scenario).
CREATE OR REPLACE VIEW dw.vw_capex_comparison AS
WITH staging_scenario AS (
    SELECT
          scenario_id
        , name
        , investment_value
        , reduction_pct
        , annual_savings_value
        , payback_months
    FROM gold.fact_investment_scenario
)
SELECT
      scenario_id
    , name
    , investment_value
    , reduction_pct
    , annual_savings_value
    , payback_months
    , RANK() OVER (ORDER BY payback_months ASC NULLS LAST) AS rank_by_payback
FROM staging_scenario;

-- Grao: pessoa x mes (residencial). Window functions: RANK/PERCENT_RANK por
-- consumo (m3) - mesma tecnica de dw.vw_property_ranking, aplicada ao
-- perfil residencial, usando so dado real (sem sintetico).
CREATE OR REPLACE VIEW dw.vw_residential_efficiency_ranking AS
WITH staging_bill AS (
    SELECT
          dpe.user_id
        , dpe.name AS person_name
        , dd.full_date AS reference_month
        , f.m3_value
        , f.total_value
    FROM gold.fact_water_bill_monthly f
    JOIN gold.dim_person dpe ON dpe.person_key = f.person_key
    JOIN gold.dim_date dd    ON dd.date_key = f.date_key
)
SELECT
      user_id
    , person_name
    , reference_month
    , m3_value
    , total_value
    , RANK()         OVER (PARTITION BY reference_month ORDER BY m3_value ASC) AS rank_efficiency
    , PERCENT_RANK() OVER (PARTITION BY reference_month ORDER BY m3_value)     AS consumption_percent_rank
FROM staging_bill;

-- Estrutura avancada: CTE RECURSIVA. Reconstroi o historico completo de
-- mudancas de cada linha de tb_region_rate subindo a cadeia de
-- tb_log_region_rate.previous_log_id (trilha de auditoria que ja existe,
-- ver audit-tables/tb_log_region_rate.sql) - sem precisar de uma hierarquia
-- de gestores inventada. Le de tb_log_region_rate (schema public), nao do
-- gold: e uma view de auditoria/governanca, nao uma view dimensional.
--
-- Exemplo de consulta (historico de UMA tarifa especifica):
--   SELECT * FROM dw.vw_audit_history_chain WHERE region_rate_id = 5 ORDER BY level;
CREATE OR REPLACE VIEW dw.vw_audit_history_chain AS
WITH RECURSIVE chain AS (
    SELECT
          id
        , region_rate_id
        , m3_value
        , operation
        , executed_by
        , executed_at
        , previous_log_id
        , 1 AS level
    FROM tb_log_region_rate
    WHERE previous_log_id IS NULL

    UNION ALL

    SELECT
          l.id
        , l.region_rate_id
        , l.m3_value
        , l.operation
        , l.executed_by
        , l.executed_at
        , l.previous_log_id
        , c.level + 1
    FROM tb_log_region_rate l
    JOIN chain c ON l.previous_log_id = c.id
)
SELECT
      id AS log_id
    , region_rate_id
    , m3_value
    , operation
    , executed_by
    , executed_at
    , level
FROM chain;

