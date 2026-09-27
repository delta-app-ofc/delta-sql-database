-- Grao: 1 cenario de investimento (referencia, sem grao de tempo/instalacao
-- proprio - alimenta so a comparacao de cenarios do CAPEX).
CREATE TABLE gold.fact_investment_scenario (
      scenario_key          SERIAL        PRIMARY KEY
    , scenario_id           INTEGER       NOT NULL UNIQUE
    , name                  VARCHAR(100)  NOT NULL
    , investment_value      NUMERIC(10,2) NOT NULL
    , reduction_pct         NUMERIC(5,2)  NOT NULL
    , annual_savings_value  NUMERIC(10,2) NOT NULL
    , payback_months        NUMERIC(6,1)
);
