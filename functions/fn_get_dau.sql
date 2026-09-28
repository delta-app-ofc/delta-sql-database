CREATE OR REPLACE FUNCTION fn_get_dau(
    p_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_dau INTEGER;
BEGIN

    IF p_date IS NULL THEN
        RAISE EXCEPTION 'A data não pode ser nula.';
    END IF;

    SELECT COUNT(DISTINCT user_id)
    INTO v_dau
    FROM tb_user_access_log
    WHERE accessed_at::DATE = p_date;

    RETURN v_dau;

END;
$$;
