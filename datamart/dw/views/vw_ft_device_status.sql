CREATE OR REPLACE VIEW dw.vw_ft_device_status AS
SELECT
      dp.organization_id
    , dp.property_id
    , dp.name                                   AS property_name
    , dp.region_name
    , ds.device_id
    , ds.is_active
    , ds.connectivity_status
    , (LOWER(ds.connectivity_status) IN ('online', 'connected')) AS is_online
    , ds.battery_level
    , (ds.battery_level IS NOT NULL AND ds.battery_level <= 20)  AS is_low_battery
    , ds.wifi_signal_rssi
    , ds.firmware_version
    , ds.last_ping_at
    , ds.unavailability_reason
FROM gold.dm_device_status ds
JOIN gold.dm_property dp ON dp.property_key = ds.property_key;

