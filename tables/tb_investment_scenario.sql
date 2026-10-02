CREATE TABLE tb_investment_scenario (
      id                                            SERIAL        PRIMARY KEY
    , organization_id                               INTEGER
    , name                                          VARCHAR(100)  NOT NULL
    , investment_value                              NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_investment_scenario_investment_value
        CHECK (investment_value >= 0)
    , reduction_pct                                 NUMERIC(5,2)  NOT NULL
      CONSTRAINT chk_tb_investment_scenario_reduction_pct
        CHECK (reduction_pct >= 0 AND reduction_pct <= 100)
    , annual_savings_value                          NUMERIC(10,2) NOT NULL
      CONSTRAINT chk_tb_investment_scenario_annual_savings_value
        CHECK (annual_savings_value >= 0)
    , payback_months                                NUMERIC(6,1)
      CONSTRAINT chk_tb_investment_scenario_payback_months
        CHECK (payback_months IS NULL OR payback_months >= 0)
    , description                                   TEXT
    , CONSTRAINT fk_tb_investment_scenario_organization
        FOREIGN KEY (organization_id)
        REFERENCES tb_organization (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
