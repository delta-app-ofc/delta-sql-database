CREATE OR REPLACE PROCEDURE gold.sp_load_dm_user_preference()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.dm_user_preference
    (
          person_key, daily_liters_target, notifications_enabled
        , quiet_start_hour, quiet_end_hour, dark_mode_enabled
    )
    SELECT
          dpe.person_key
        , up.daily_liters_target
        , up.notifications_enabled
        , up.quiet_start_hour
        , up.quiet_end_hour
        , up.dark_mode_enabled
    FROM silver.dm_user_preference up
    JOIN gold.dm_person dpe ON dpe.user_id = up.user_id
    ON CONFLICT (person_key) DO UPDATE
        SET daily_liters_target   = EXCLUDED.daily_liters_target
          , notifications_enabled = EXCLUDED.notifications_enabled
          , quiet_start_hour      = EXCLUDED.quiet_start_hour
          , quiet_end_hour        = EXCLUDED.quiet_end_hour
          , dark_mode_enabled     = EXCLUDED.dark_mode_enabled;

END;
$$;
