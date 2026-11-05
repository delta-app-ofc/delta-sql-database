CREATE OR REPLACE VIEW dw.vw_ft_alert AS
SELECT
      fa.alert_key
    , dp.property_id
    , dp.name           AS property_name
    , dpe.user_id
    , dpe.name          AS person_name
    , dd.full_date      AS alert_date
    , fa.device_id
    , fa.alert_type
    , fa.severity
    , fa.triggered_at
    , fa.resolved_at
    , ROUND(EXTRACT(EPOCH FROM (fa.resolved_at - fa.triggered_at)) / 60.0, 1) AS resolution_minutes
FROM gold.ft_alert fa
JOIN gold.dm_property dp  ON dp.property_key  = fa.property_key
JOIN gold.dm_person   dpe ON dpe.person_key   = fa.person_key
JOIN gold.dm_date     dd  ON dd.date_key      = fa.date_key;
