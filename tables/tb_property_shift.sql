CREATE TABLE tb_property_shift (
      id                    SERIAL      PRIMARY KEY
    , property_id           INTEGER     NOT NULL
    , start_time            TIME        NOT NULL
    , end_time              TIME        NOT NULL
      CONSTRAINT chk_tb_property_shift_end_after_start
        CHECK (end_time > start_time)
    , CONSTRAINT fk_tb_property_shift_property
        FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
