CREATE TABLE tb_log_investment_scenario (

      id                    SERIAL PRIMARY KEY

    , investment_scenario_id INTEGER

    , organization_id       INTEGER
    , name                  VARCHAR(100)
    , investment_value      NUMERIC(10,2)
    , reduction_pct         NUMERIC(5,2)
    , annual_savings_value  NUMERIC(10,2)
    , payback_months        NUMERIC(6,1)
    , description           TEXT

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT
    , CONSTRAINT fk_tb_log_investment_scenario_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_investment_scenario (id)

);
