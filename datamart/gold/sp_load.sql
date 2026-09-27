CREATE OR REPLACE PROCEDURE gold.sp_load()
LANGUAGE plpgsql
AS $$
BEGIN

    CALL gold.sp_load_dm_date();
    CALL gold.sp_load_dm_property();
    CALL gold.sp_load_dm_person();
    CALL gold.sp_load_ft_consumption_daily();
    CALL gold.sp_load_ft_water_bill_monthly();
    CALL gold.sp_load_ft_investment_scenario();

END;
$$;
