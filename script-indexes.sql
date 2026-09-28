CREATE INDEX idx_stage_consumption_summary_device_window
    ON stage.consumption_summary (device_id, window_started_at DESC);


CREATE INDEX idx_gold_dm_property_organization
    ON gold.dm_property (organization_name);


CREATE INDEX idx_log_region_rate_previous_log_id
    ON tb_log_region_rate (previous_log_id);

