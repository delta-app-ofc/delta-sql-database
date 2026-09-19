CREATE TABLE tb_region_rate (

      id                                          SERIAL        PRIMARY KEY
      
    , region_id                                   INTEGER       NOT NULL

    , m3_value                                    NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_region_rate_m3_value CHECK (m3_value > 0)

    , initial_validity                            DATE          NOT NULL

    , final_validity                              DATE
      CONSTRAINT chk_tb_region_rate_final_validity
        CHECK (final_validity IS NULL OR final_validity >= initial_validity)

    , CONSTRAINT uq_tb_region_rate_region_validity
        UNIQUE (region_id, initial_validity)

    , CONSTRAINT fk_tb_region_rate_region
        FOREIGN KEY (region_id)
        REFERENCES tb_region (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);