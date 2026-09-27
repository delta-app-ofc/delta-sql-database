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
