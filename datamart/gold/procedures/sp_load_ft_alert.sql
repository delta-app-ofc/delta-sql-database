CREATE OR REPLACE PROCEDURE gold.sp_load_ft_alert()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_alert (property_key, person_key, date_key, device_id, alert_type, severity, triggered_at, resolved_at)
    SELECT
          dp.property_key
        , dpe.person_key
        , TO_CHAR(a.triggered_at, 'YYYYMMDD')::INTEGER
        , a.device_id
        , a.alert_type
        , a.severity
        , a.triggered_at
        , a.resolved_at
    FROM silver.ft_alert a
    JOIN gold.dm_property dp  ON dp.property_id = a.property_id
    JOIN gold.dm_person   dpe ON dpe.user_id    = a.user_id
    JOIN gold.dm_date     dd  ON dd.date_key    = TO_CHAR(a.triggered_at, 'YYYYMMDD')::INTEGER
    ON CONFLICT (device_id, alert_type, triggered_at) DO UPDATE
        SET severity    = EXCLUDED.severity
          , resolved_at = EXCLUDED.resolved_at;

END;
$$;
