CREATE TABLE silver.dm_user_preference (
      user_id               INTEGER       PRIMARY KEY
    , name                  VARCHAR(100)  NOT NULL
    , daily_liters_target   INTEGER
    , notifications_enabled BOOLEAN
    , quiet_start_hour      VARCHAR(10)
    , quiet_end_hour        VARCHAR(10)
    , dark_mode_enabled     BOOLEAN       NOT NULL
);
