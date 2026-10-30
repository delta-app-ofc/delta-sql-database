CREATE TABLE tb_city_region (
      id                                 SERIAL      PRIMARY KEY
    , city                               VARCHAR(60) NOT NULL
    , state                              CHAR(2)     NOT NULL
      CONSTRAINT chk_tb_city_region_state CHECK (state ~ '^[A-Z]{2}$')
    , region_id                          INTEGER     NOT NULL
    , CONSTRAINT uq_tb_city_region_city_state UNIQUE (city, state)
    , CONSTRAINT fk_tb_city_region_region     FOREIGN KEY (region_id)
        REFERENCES tb_region (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);