CREATE OR REPLACE FUNCTION fn_organization_can_estimate(
    p_property_ids INTEGER[]
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN

    -- Uma linha em gold.ft_consumption_daily já implica tarifa válida calculada pelo ETL
    RETURN EXISTS
    (
        SELECT 1
          FROM gold.ft_consumption_daily f
          JOIN gold.dm_property dp
            ON dp.property_key = f.property_key
         WHERE dp.property_id = ANY(p_property_ids)
    );

END;
$$;
