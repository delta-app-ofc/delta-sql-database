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
