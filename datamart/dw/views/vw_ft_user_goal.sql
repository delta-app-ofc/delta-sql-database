CREATE OR REPLACE VIEW dw.vw_ft_user_goal AS
WITH consumption_per_person AS (
    SELECT
          up.user_id
        , AVG(cd.total_liters) AS avg_liters_last_30d
    FROM tb_user_property up
    JOIN gold.dm_property          gp ON gp.property_id   = up.property_id
    JOIN gold.ft_consumption_daily cd ON cd.property_key  = gp.property_key
    JOIN gold.dm_date              dd ON dd.date_key      = cd.date_key
    WHERE dd.full_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY up.user_id
)
SELECT
      dpe.user_id
    , dpe.name
    , pr.daily_liters_target
    , COALESCE(c.avg_liters_last_30d, 0) AS avg_liters_last_30d
    , ROUND(COALESCE(c.avg_liters_last_30d, 0) / NULLIF(pr.daily_liters_target, 0) * 100, 1) AS pct_of_target
FROM gold.dm_user_preference pr
JOIN gold.dm_person dpe ON dpe.person_key = pr.person_key
LEFT JOIN consumption_per_person c ON c.user_id = dpe.user_id;
