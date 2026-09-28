CREATE OR REPLACE PROCEDURE gold.sp_load_dm_date()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO gold.dm_date (date_key, full_date, day_of_week, day_name, week_of_year, month_number, quarter_number, year_number, is_weekend)
    SELECT
          TO_CHAR(d, 'YYYYMMDD')::INTEGER
        , d
        , EXTRACT(DOW FROM d)
        , TRIM(TO_CHAR(d, 'Day'))
        , EXTRACT(WEEK FROM d)
        , EXTRACT(MONTH FROM d)
        , EXTRACT(QUARTER FROM d)
        , EXTRACT(YEAR FROM d)
        , EXTRACT(DOW FROM d) IN (0, 6)
    FROM generate_series('2024-01-01'::DATE, '2028-12-31'::DATE, INTERVAL '1 day') AS d
    ON CONFLICT (date_key) DO NOTHING;

END;
$$;
