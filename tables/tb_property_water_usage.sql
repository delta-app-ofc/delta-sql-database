CREATE TABLE tb_property_water_usage (
      id                            SERIAL      PRIMARY KEY
    , property_id                   INTEGER     NOT NULL
    , water_usage_type_id           INTEGER     NOT NULL
    , CONSTRAINT uq_tb_property_water_usage
        UNIQUE (property_id, water_usage_type_id)
    , CONSTRAINT fk_tb_property_water_usage_property
        FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_property_water_usage_type
        FOREIGN KEY (water_usage_type_id)
        REFERENCES tb_water_usage_type (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
