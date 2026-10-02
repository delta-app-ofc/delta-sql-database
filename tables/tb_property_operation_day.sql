CREATE TABLE tb_property_operation_day (
      id                            SERIAL      PRIMARY KEY
    , property_id                   INTEGER     NOT NULL
    , day_of_week_id                INTEGER     NOT NULL
    , CONSTRAINT uq_tb_property_operation_day
        UNIQUE (property_id, day_of_week_id)
    , CONSTRAINT fk_tb_property_operation_day_property
        FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_property_operation_day_day_of_week
        FOREIGN KEY (day_of_week_id)
        REFERENCES tb_day_of_week (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
