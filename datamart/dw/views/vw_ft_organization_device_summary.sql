CREATE OR REPLACE VIEW dw.vw_ft_organization_device_summary AS
WITH agg_devices AS (
    SELECT
          organization_id
        , COUNT(*) FILTER (WHERE is_active)                            AS devices_paired
        , COUNT(*) FILTER (WHERE is_active AND is_online)              AS devices_online
        , COUNT(*) FILTER (WHERE is_active AND is_low_battery)         AS devices_low_battery
        , COUNT(DISTINCT property_id) FILTER (WHERE is_active)         AS properties_with_device
    FROM dw.vw_ft_device_status
    GROUP BY organization_id
),
agg_properties AS (
    SELECT organization_id, COUNT(*) AS properties_total
    FROM gold.dm_property
    WHERE organization_id IS NOT NULL
    GROUP BY organization_id
)
SELECT
      p.organization_id
    , p.properties_total
    , COALESCE(d.devices_paired, 0)          AS devices_paired
    , COALESCE(d.devices_online, 0)          AS devices_online
    , COALESCE(d.devices_low_battery, 0)     AS devices_low_battery
    , p.properties_total - COALESCE(d.properties_with_device, 0) AS properties_without_device
FROM agg_properties p
LEFT JOIN agg_devices d ON d.organization_id = p.organization_id;

