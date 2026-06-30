CREATE TABLE tb_region_rate (

      id                                          SERIAL        PRIMARY KEY
    , region_id                                   INTEGER       NOT NULL
    , initial_range                               NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_region_rate_initial_range CHECK (initial_range >= 0)

    , final_range                                 NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_region_rate_final_range   CHECK (final_range > initial_range)

    , m3_value                                    NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_region_rate_m3_value CHECK (m3_value > 0)

    , initial_validity                            DATE          NOT NULL

    , final_validity                              DATE
      CONSTRAINT chk_tb_region_rate_final_validity
        CHECK (final_validity IS NULL OR final_validity >= initial_validity)

    , CONSTRAINT fk_tb_region_rate_region
        FOREIGN KEY (region_id)
        REFERENCES tb_region (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);