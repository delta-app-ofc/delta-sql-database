CREATE OR REPLACE PROCEDURE silver.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    CALL silver.sp_load_ft_consumption_reading();
    CALL silver.sp_load_ft_consumption_daily();
    CALL silver.sp_load_dm_property();
    CALL silver.sp_load_dm_person();
    CALL silver.sp_load_ft_water_bill();

END;
$$;
