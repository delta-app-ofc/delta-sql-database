-- Extensao 1:1 de tb_property (NAO usa heranca nativa do Postgres via
-- INHERITS - ver decisao registrada no TASK.md). Testado com heranca real
-- primeiro e descoberto um problema serio: FOREIGN KEY de OUTRAS tabelas que
-- referenciam tb_property (id) (tb_device, tb_user_property, e as novas
-- tb_property_shift/tb_property_water_usage/tb_property_operation_day) NAO
-- veem linhas gravadas na subtabela filha - a constraint de FK so olha a
-- tabela literal que ela referencia, nao as filhas por heranca. Isso quebraria
-- de verdade o vinculo de dispositivo (tb_device) pra qualquer instalacao
-- industrial com perfil operacional completo. Por isso aqui e uma extensao
-- comum via FK 1:1 (property_id e ao mesmo tempo PK e FK pra tb_property):
-- a linha-base continua sempre em tb_property, e so os campos extras do
-- perfil operacional (turnos, fonte de agua) ficam aqui.
CREATE TABLE tb_property_operational_profile (
      property_id           INTEGER     PRIMARY KEY
    , shift_count           SMALLINT
      CONSTRAINT chk_tb_property_operational_profile_shift_count
        CHECK (shift_count IS NULL OR shift_count > 0)
    , main_water_source     VARCHAR(20) NOT NULL
      CONSTRAINT chk_tb_property_operational_profile_main_water_source
        CHECK (main_water_source IN ('CONCESSIONARIA', 'POCO_ARTESIANO', 'CISTERNA', 'REUSO'))
    , CONSTRAINT fk_tb_property_operational_profile_property
        FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
