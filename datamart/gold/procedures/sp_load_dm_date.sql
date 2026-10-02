CREATE OR REPLACE PROCEDURE gold.sp_load_dm_date()
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_date DATE;
    v_max_date DATE;
BEGIN

    -- Intervalo de referência (5 anos pra trás, 2 pra frente) combinado com as datas
    -- reais que já existem na Silver - nunca deixa a dimensão mais curta que o dado real.
    SELECT
          LEAST(CURRENT_DATE - INTERVAL '5 years', MIN(d))::DATE
        , GREATEST(CURRENT_DATE + INTERVAL '2 years', MAX(d))::DATE
      INTO v_min_date, v_max_date
      FROM (
          SELECT consumption_day AS d FROM silver.ft_consumption_daily
          UNION ALL
          SELECT bill_month      AS d FROM silver.ft_water_bill
      ) datas;

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
    FROM generate_series(v_min_date, v_max_date, INTERVAL '1 day') AS d
    ON CONFLICT (date_key) DO NOTHING;

END;
$$;
