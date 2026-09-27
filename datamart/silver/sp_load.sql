CREATE OR REPLACE PROCEDURE silver.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO silver.consumption_reading (property_id, read_at, volume_liters, flow_lmin)
    SELECT r.property_id, r.read_at, r.volume_liters, r.flow_lmin
    FROM stage.consumption_reading_raw r
    ON CONFLICT (property_id, read_at) DO NOTHING;

    WITH daily AS (
        SELECT
              property_id
            , DATE(read_at)                AS consumption_day
            , SUM(volume_liters)            AS total_liters
            , AVG(flow_lmin)                AS avg_flow_lmin
        FROM silver.consumption_reading
        GROUP BY property_id, DATE(read_at)
    )
    INSERT INTO silver.consumption_daily (property_id, consumption_day, total_liters, avg_flow_lmin)
    SELECT property_id, consumption_day, total_liters, avg_flow_lmin
    FROM daily
    ON CONFLICT (property_id, consumption_day) DO UPDATE
        SET total_liters  = EXCLUDED.total_liters
          , avg_flow_lmin = EXCLUDED.avg_flow_lmin;

    TRUNCATE TABLE silver.property;

    INSERT INTO silver.property
    (
          property_id, name, property_type, classification_id, classification_group
        , region_id, city, state, built_area_m2
        , organization_id, organization_name
        , has_operational_profile, shift_count, main_water_source
    )
    SELECT
          p.id
        , p.name
        , p.type
        , p.classification_id
        , pc.group_name
        , a.region_id
        , a.city
        , a.state
        , p.built_area_m2
        , p.organization_id
        , o.trade_name
        , (op.property_id IS NOT NULL)
        , op.shift_count
        , op.main_water_source
    FROM tb_property p
    JOIN tb_property_classification pc ON pc.id = p.classification_id
    JOIN tb_address a                  ON a.id = p.address_id
    LEFT JOIN tb_organization o        ON o.id = p.organization_id
    LEFT JOIN tb_property_operational_profile op ON op.property_id = p.id;

    TRUNCATE TABLE silver.person;

    INSERT INTO silver.person (user_id, name, profile_type)
    SELECT
          u.id
        , u.name
        , CASE WHEN uo.user_id IS NOT NULL THEN 'GESTOR' ELSE 'RESIDENCIAL' END
    FROM tb_user u
    LEFT JOIN (SELECT DISTINCT user_id FROM tb_user_organization) uo ON uo.user_id = u.id;

    INSERT INTO silver.water_bill (user_id, user_name, bill_month, total_value, m3_value)
    SELECT b.user_id, u.name, b.month, b.total_value, b.m3_value
    FROM tb_last_water_bill b
    JOIN tb_user u ON u.id = b.user_id
    ON CONFLICT (user_id, bill_month) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value     = EXCLUDED.m3_value;

END;
$$;
