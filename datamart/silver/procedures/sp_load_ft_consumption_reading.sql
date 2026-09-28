CREATE OR REPLACE PROCEDURE silver.sp_load_ft_consumption_reading()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.ft_consumption_reading (property_id, device_id, read_at, volume_liters, flow_lmin)
    SELECT
          d.property_id
        , s.device_id
        , s.window_started_at
        , s.consumption_liters
        , s.lpm_average
    FROM stage.consumption_summary s
    JOIN tb_device d ON d.device_id = s.device_id
    ON CONFLICT (device_id, read_at) DO NOTHING;

END;
$$;
