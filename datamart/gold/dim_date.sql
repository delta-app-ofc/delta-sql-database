-- Grao: 1 dia. Gerada via generate_series (gold.sp_load()), nao depende de
-- tabela de calendario externa.
CREATE TABLE gold.dim_date (
      date_key              INTEGER     PRIMARY KEY
    , full_date             DATE        NOT NULL UNIQUE
    , day_of_week           SMALLINT    NOT NULL
    , day_name              VARCHAR(20) NOT NULL
    , week_of_year          SMALLINT    NOT NULL
    , month_number          SMALLINT    NOT NULL
    , quarter_number        SMALLINT    NOT NULL
    , year_number           SMALLINT    NOT NULL
    , is_weekend            BOOLEAN     NOT NULL
);
