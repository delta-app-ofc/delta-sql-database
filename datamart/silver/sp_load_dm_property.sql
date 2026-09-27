CREATE OR REPLACE PROCEDURE silver.sp_load_dm_property()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE silver.dm_property;

    INSERT INTO silver.dm_property
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

END;
$$;
