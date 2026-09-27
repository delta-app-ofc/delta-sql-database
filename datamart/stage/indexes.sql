CREATE INDEX idx_stage_consumption_summary_device_window
    ON stage.consumption_summary (device_id, window_started_at DESC);
