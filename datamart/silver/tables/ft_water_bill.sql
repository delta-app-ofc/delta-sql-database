CREATE TABLE silver.ft_water_bill (
      id                    BIGSERIAL     PRIMARY KEY
    , user_id               INTEGER       NOT NULL
    , user_name             VARCHAR(100)  NOT NULL
    , bill_month            DATE          NOT NULL
    , total_value           NUMERIC(10,2) NOT NULL
    , m3_value              NUMERIC(10,2) NOT NULL
    , CONSTRAINT uq_silver_ft_water_bill_user_month
        UNIQUE (user_id, bill_month)
);
