CREATE TABLE stage.user_preferences (
      id                    BIGSERIAL     PRIMARY KEY
    , mongo_id              CHAR(24)      UNIQUE
    , user_id               INTEGER       NOT NULL
    , daily_liters_target   INTEGER
    , notifications_enabled BOOLEAN
    , quiet_start_hour      VARCHAR(10)
    , quiet_end_hour        VARCHAR(10)
    , dark_mode_enabled     BOOLEAN       NOT NULL
    , loaded_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
