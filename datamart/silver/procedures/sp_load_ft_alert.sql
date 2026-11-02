CREATE OR REPLACE PROCEDURE silver.sp_load_ft_alert()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.ft_alert (property_id, user_id, device_id, alert_type, severity, triggered_at, resolved_at)
    SELECT
          d.property_id
        , a.user_id
        , a.device_id
        , a.alert_type
        , a.severity
        , a.triggered_at
        , a.resolved_at
    FROM stage.alerts_history a
    JOIN tb_device d ON d.device_id = a.device_id
    ON CONFLICT (device_id, alert_type, triggered_at) DO UPDATE
        SET severity    = EXCLUDED.severity
          , resolved_at = EXCLUDED.resolved_at;

END;
$$;
