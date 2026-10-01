CREATE OR REPLACE PROCEDURE gold.sp_load_dm_property()
LANGUAGE plpgsql
AS $$
BEGIN

    -- Nunca remove uma propriedade que ainda tem fato vinculado (preserva histórico) -
    -- só limpa dimensão órfã sem nenhum dado de consumo associado.
    DELETE FROM gold.dm_property
    WHERE property_id NOT IN (SELECT property_id FROM silver.dm_property)
      AND property_key NOT IN (SELECT property_key FROM gold.ft_consumption_daily);

    INSERT INTO gold.dm_property (property_id, name, property_type, classification_group, city, state, built_area_m2, organization_name, has_operational_profile)
    SELECT property_id, name, property_type, classification_group, city, state, built_area_m2, organization_name, has_operational_profile
    FROM silver.dm_property
    ON CONFLICT (property_id) DO UPDATE
        SET name                     = EXCLUDED.name
          , property_type            = EXCLUDED.property_type
          , classification_group     = EXCLUDED.classification_group
          , city                     = EXCLUDED.city
          , state                    = EXCLUDED.state
          , built_area_m2            = EXCLUDED.built_area_m2
          , organization_name        = EXCLUDED.organization_name
          , has_operational_profile  = EXCLUDED.has_operational_profile;

END;
$$;
