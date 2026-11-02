CREATE OR REPLACE PROCEDURE silver.sp_load_dm_user_preference()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.dm_user_preference
    (
          user_id, name, daily_liters_target, notifications_enabled
        , quiet_start_hour, quiet_end_hour, dark_mode_enabled
    )
    SELECT
          p.user_id
        , u.name
        , p.daily_liters_target
        , p.notifications_enabled
        , p.quiet_start_hour
        , p.quiet_end_hour
        , p.dark_mode_enabled
    FROM stage.user_preferences p
    JOIN tb_user u ON u.id = p.user_id
    ON CONFLICT (user_id) DO UPDATE
        SET name                  = EXCLUDED.name
          , daily_liters_target   = EXCLUDED.daily_liters_target
          , notifications_enabled = EXCLUDED.notifications_enabled
          , quiet_start_hour      = EXCLUDED.quiet_start_hour
          , quiet_end_hour        = EXCLUDED.quiet_end_hour
          , dark_mode_enabled     = EXCLUDED.dark_mode_enabled;

END;
$$;
