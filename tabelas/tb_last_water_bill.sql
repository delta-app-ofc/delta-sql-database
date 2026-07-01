CREATE TABLE tb_last_water_bill (
      id                    SERIAL        PRIMARY KEY
    , user_id               INTEGER       NOT NULL
    , month                 VARCHAR(20)   NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_last_water_bill_total_value
          CHECK (total_value >= 0)
    , m3_value              NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_last_water_bill_m3_value
          CHECK (m3_value >= 0)
    , CONSTRAINT uq_tb_last_water_bill_user_month
        UNIQUE (user_id, month)
    , CONSTRAINT fk_tb_last_water_bill_user
        FOREIGN KEY (user_id)
        REFERENCES tb_user (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);