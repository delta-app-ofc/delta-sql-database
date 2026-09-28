CREATE OR REPLACE PROCEDURE gold.sp_load_ft_water_bill_monthly()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.ft_water_bill_monthly (person_key, date_key, total_value, m3_value)
    SELECT
          dp.person_key
        , TO_CHAR(wb.bill_month, 'YYYYMMDD')::INTEGER
        , wb.total_value
        , wb.m3_value
    FROM silver.ft_water_bill wb
    JOIN gold.dm_person dp ON dp.user_id = wb.user_id
    ON CONFLICT (person_key, date_key) DO UPDATE
        SET total_value = EXCLUDED.total_value
          , m3_value    = EXCLUDED.m3_value;

END;
$$;
