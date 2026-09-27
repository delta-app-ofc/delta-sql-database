CREATE OR REPLACE VIEW dw.vw_residential_efficiency_ranking AS
WITH staging_bill AS (
    SELECT
          dpe.user_id
        , dpe.name AS person_name
        , dd.full_date AS reference_month
        , f.m3_value
        , f.total_value
    FROM gold.fact_water_bill_monthly f
    JOIN gold.dim_person dpe ON dpe.person_key = f.person_key
    JOIN gold.dim_date dd    ON dd.date_key = f.date_key
)
SELECT
      user_id
    , person_name
    , reference_month
    , m3_value
    , total_value
    , RANK()         OVER (PARTITION BY reference_month ORDER BY m3_value ASC) AS rank_efficiency
    , PERCENT_RANK() OVER (PARTITION BY reference_month ORDER BY m3_value)     AS consumption_percent_rank
FROM staging_bill;
