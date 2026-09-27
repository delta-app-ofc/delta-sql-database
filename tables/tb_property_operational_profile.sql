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
