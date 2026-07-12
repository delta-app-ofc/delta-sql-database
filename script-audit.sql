DROP TABLE IF EXISTS tb_log_address           CASCADE;
DROP TABLE IF EXISTS tb_log_habit             CASCADE;
DROP TABLE IF EXISTS tb_log_day_of_week       CASCADE;
DROP TABLE IF EXISTS tb_log_region            CASCADE;
DROP TABLE IF EXISTS tb_log_device            CASCADE;
DROP TABLE IF EXISTS tb_log_property          CASCADE;
DROP TABLE IF EXISTS tb_log_user              CASCADE;
DROP TABLE IF EXISTS tb_log_user_property     CASCADE;
DROP TABLE IF EXISTS tb_log_last_water_bill   CASCADE;
DROP TABLE IF EXISTS tb_log_user_habit_day    CASCADE;
DROP TABLE IF EXISTS tb_log_user_habit        CASCADE;
DROP TABLE IF EXISTS tb_log_region_rate       CASCADE;

DROP TRIGGER IF EXISTS trg_log_region          ON tb_region;
DROP TRIGGER IF EXISTS trg_log_day_of_week     ON tb_day_of_week;
DROP TRIGGER IF EXISTS trg_log_habit           ON tb_habit;
DROP TRIGGER IF EXISTS trg_log_address         ON tb_address;
DROP TRIGGER IF EXISTS trg_log_user            ON tb_user;
DROP TRIGGER IF EXISTS trg_log_property        ON tb_property;
DROP TRIGGER IF EXISTS trg_log_user_property   ON tb_user_property;
DROP TRIGGER IF EXISTS trg_log_device          ON tb_device;
DROP TRIGGER IF EXISTS trg_log_region_rate     ON tb_region_rate;
DROP TRIGGER IF EXISTS trg_log_user_habit      ON tb_user_habit;
DROP TRIGGER IF EXISTS trg_log_user_habit_day  ON tb_user_habit_day;
DROP TRIGGER IF EXISTS trg_log_last_water_bill ON tb_last_water_bill;


CREATE TABLE tb_log_region (

      id                      SERIAL       PRIMARY KEY

    , region_id               INTEGER
    , name                    VARCHAR(20)

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_region_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_region (id)
);

CREATE OR REPLACE FUNCTION fn_log_region()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_region
        WHERE region_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_region
        WHERE region_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_region.';


        INSERT INTO tb_log_region
        (
              region_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_region. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_region
        (
              region_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_region.';


        INSERT INTO tb_log_region
        (
              region_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_region
AFTER INSERT OR UPDATE OR DELETE
ON tb_region
FOR EACH ROW
EXECUTE FUNCTION fn_log_region();

CREATE TABLE tb_log_day_of_week (

      id                      SERIAL       PRIMARY KEY

    , day_of_week_id          INTEGER
    , name                    VARCHAR(20)

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_day_of_week_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_day_of_week (id)
);

CREATE OR REPLACE FUNCTION fn_log_day_of_week()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_day_of_week
        WHERE day_of_week_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_day_of_week
        WHERE day_of_week_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_day_of_week.';


        INSERT INTO tb_log_day_of_week
        (
              day_of_week_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_day_of_week. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_day_of_week
        (
              day_of_week_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_day_of_week.';


        INSERT INTO tb_log_day_of_week
        (
              day_of_week_id
            , name

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.name

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_day_of_week
AFTER INSERT OR UPDATE OR DELETE
ON tb_day_of_week
FOR EACH ROW
EXECUTE FUNCTION fn_log_day_of_week();

CREATE TABLE tb_log_habit (

      id                      SERIAL       PRIMARY KEY

    , habit_id                INTEGER
    , name                    VARCHAR(30)
    , description             TEXT

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_habit_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_habit (id)
);


CREATE OR REPLACE FUNCTION fn_log_habit()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_habit
        WHERE habit_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_habit
        WHERE habit_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_habit.';


        INSERT INTO tb_log_habit
        (
              habit_id
            , name
            , description

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name
            , NEW.description

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_habit. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_habit
        (
              habit_id
            , name
            , description

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.name
            , NEW.description

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_habit.';


        INSERT INTO tb_log_habit
        (
              habit_id
            , name
            , description

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.name
            , OLD.description

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_habit
AFTER INSERT OR UPDATE OR DELETE
ON tb_habit
FOR EACH ROW
EXECUTE FUNCTION fn_log_habit();

CREATE TABLE tb_log_address (

      id                      SERIAL       PRIMARY KEY

    , address_id              INTEGER
    , region_id               INTEGER
    , cep                     CHAR(8)
    , city                    VARCHAR(60)
    , state                   VARCHAR(30)

    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , previous_log_id         INTEGER
    , log_description         TEXT

    , CONSTRAINT fk_tb_log_address_previous_log
        FOREIGN KEY (previous_log_id)
        REFERENCES tb_log_address (id)
);

CREATE OR REPLACE FUNCTION fn_log_address()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_address
        WHERE address_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_address
        WHERE address_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_address.';


        INSERT INTO tb_log_address
        (
              address_id
            , region_id
            , cep
            , city
            , state

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.region_id
            , NEW.cep
            , NEW.city
            , NEW.state

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_address. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_address
        (
              address_id
            , region_id
            , cep
            , city
            , state

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.region_id
            , NEW.cep
            , NEW.city
            , NEW.state

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_address.';


        INSERT INTO tb_log_address
        (
              address_id
            , region_id
            , cep
            , city
            , state

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.region_id
            , OLD.cep
            , OLD.city
            , OLD.state

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_address
AFTER INSERT OR UPDATE OR DELETE
ON tb_address
FOR EACH ROW
EXECUTE FUNCTION fn_log_address();

CREATE TABLE tb_log_user (

      id                    SERIAL PRIMARY KEY

    , user_id               INTEGER

    , name                  VARCHAR(100)
    , email                 VARCHAR(255)
    , phone                 VARCHAR(15)
    , birth_date            DATE
    , registration_date     DATE
    , is_active             BOOLEAN
    , is_admin              BOOLEAN
    , is_manager            BOOLEAN

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_user()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_user
        WHERE user_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_user
        WHERE user_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_user.';


        INSERT INTO tb_log_user
        (
              user_id

            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id

            , NEW.name
            , NEW.email
            , NEW.phone
            , NEW.birth_date
            , NEW.registration_date
            , NEW.is_active
            , NEW.is_admin
            , NEW.is_manager

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_user. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_user
        (
              user_id

            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id

            , NEW.name
            , NEW.email
            , NEW.phone
            , NEW.birth_date
            , NEW.registration_date
            , NEW.is_active
            , NEW.is_admin
            , NEW.is_manager

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_user.';


        INSERT INTO tb_log_user
        (
              user_id

            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id

            , OLD.name
            , OLD.email
            , OLD.phone
            , OLD.birth_date
            , OLD.registration_date
            , OLD.is_active
            , OLD.is_admin
            , OLD.is_manager

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_user
AFTER INSERT OR UPDATE OR DELETE
ON tb_user
FOR EACH ROW
EXECUTE FUNCTION fn_log_user();

CREATE TABLE tb_log_property (

      id                    SERIAL PRIMARY KEY

    , property_id           INTEGER

    , name                  VARCHAR(100)
    , type                  VARCHAR(20)
    , classification        VARCHAR(20)
    , address_id            INTEGER
    , registration_date     DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_property()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_property
        WHERE property_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_property
        WHERE property_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_property.';


        INSERT INTO tb_log_property
        (
              property_id

            , name
            , type
            , classification
            , address_id
            , registration_date

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id

            , NEW.name
            , NEW.type
            , NEW.classification
            , NEW.address_id
            , NEW.registration_date

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_property. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_property
        (
              property_id

            , name
            , type
            , classification
            , address_id
            , registration_date

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id

            , NEW.name
            , NEW.type
            , NEW.classification
            , NEW.address_id
            , NEW.registration_date

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_property.';


        INSERT INTO tb_log_property
        (
              property_id

            , name
            , type
            , classification
            , address_id
            , registration_date

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id

            , OLD.name
            , OLD.type
            , OLD.classification
            , OLD.address_id
            , OLD.registration_date

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_property
AFTER INSERT OR UPDATE OR DELETE
ON tb_property
FOR EACH ROW
EXECUTE FUNCTION fn_log_property();

CREATE TABLE tb_log_user_property (

      id                    SERIAL PRIMARY KEY

    , user_property_id      INTEGER
    , user_id               INTEGER
    , property_id           INTEGER
    , association_date      DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_user_property()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_property
        WHERE user_property_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_property
        WHERE user_property_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;

    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_user_property.';

        INSERT INTO tb_log_user_property
        (
              user_property_id
            , user_id
            , property_id
            , association_date
            , operation
            , executed_by
            , executed_at
            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_id
            , NEW.property_id
            , NEW.association_date
            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , previous_log_id
            , log_description
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_user_property. Campos alterados:';

        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;

            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;

        INSERT INTO tb_log_user_property
        (
              user_property_id
            , user_id
            , property_id
            , association_date
            , operation
            , executed_by
            , executed_at
            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_id
            , NEW.property_id
            , NEW.association_date
            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , previous_log_id
            , log_description
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_user_property.';

        INSERT INTO tb_log_user_property
        (
              user_property_id
            , user_id
            , property_id
            , association_date
            , operation
            , executed_by
            , executed_at
            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.user_id
            , OLD.property_id
            , OLD.association_date
            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , previous_log_id
            , log_description
        );

        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_user_property
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_property
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_property();

CREATE TABLE tb_log_device (

      id                    SERIAL PRIMARY KEY

    , device_id_log         INTEGER
    , device_id             INTEGER
    , property_id           INTEGER
    , is_active             BOOLEAN
    , installation_date     DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_device()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_device
        WHERE device_id_log = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_device
        WHERE device_id_log = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;

    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_device.';

        INSERT INTO tb_log_device
        (
              device_id_log
            , device_id
            , property_id
            , is_active
            , installation_date
            , operation
            , executed_by
            , executed_at
            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.device_id
            , NEW.property_id
            , NEW.is_active
            , NEW.installation_date
            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , previous_log_id
            , log_description
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_device. Campos alterados:';

        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;

            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;

        INSERT INTO tb_log_device
        (
              device_id_log
            , device_id
            , property_id
            , is_active
            , installation_date
            , operation
            , executed_by
            , executed_at
            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.device_id
            , NEW.property_id
            , NEW.is_active
            , NEW.installation_date
            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , previous_log_id
            , log_description
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_device.';

        INSERT INTO tb_log_device
        (
              device_id_log
            , device_id
            , property_id
            , is_active
            , installation_date
            , operation
            , executed_by
            , executed_at
            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.device_id
            , OLD.property_id
            , OLD.is_active
            , OLD.installation_date
            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , previous_log_id
            , log_description
        );

        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_device
AFTER INSERT OR UPDATE OR DELETE
ON tb_device
FOR EACH ROW
EXECUTE FUNCTION fn_log_device();

CREATE TABLE tb_log_region_rate (

      id                    SERIAL PRIMARY KEY

    , region_rate_id        INTEGER
    , region_id             INTEGER
    , m3_value              NUMERIC(10,2)
    , initial_validity      DATE
    , final_validity        DATE

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_region_rate()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_region_rate
        WHERE region_rate_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_region_rate
        WHERE region_rate_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_region_rate.';


        INSERT INTO tb_log_region_rate
        (
              region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.region_id
            , NEW.m3_value
            , NEW.initial_validity
            , NEW.final_validity

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_region_rate. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_region_rate
        (
              region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.region_id
            , NEW.m3_value
            , NEW.initial_validity
            , NEW.final_validity

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_region_rate.';


        INSERT INTO tb_log_region_rate
        (
              region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.region_id
            , OLD.m3_value
            , OLD.initial_validity
            , OLD.final_validity

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_region_rate
AFTER INSERT OR UPDATE OR DELETE
ON tb_region_rate
FOR EACH ROW
EXECUTE FUNCTION fn_log_region_rate();

CREATE TABLE tb_log_user_habit (

      id                    SERIAL PRIMARY KEY

    , user_habit_id         INTEGER
    , user_id               INTEGER
    , habit_id              INTEGER
    , frequency             INTEGER

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_user_habit()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_habit
        WHERE user_habit_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_habit
        WHERE user_habit_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_user_habit.';


        INSERT INTO tb_log_user_habit
        (
              user_habit_id
            , user_id
            , habit_id
            , frequency

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_id
            , NEW.habit_id
            , NEW.frequency

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_user_habit. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_user_habit
        (
              user_habit_id
            , user_id
            , habit_id
            , frequency

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_id
            , NEW.habit_id
            , NEW.frequency

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_user_habit.';


        INSERT INTO tb_log_user_habit
        (
              user_habit_id
            , user_id
            , habit_id
            , frequency

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.user_id
            , OLD.habit_id
            , OLD.frequency

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_user_habit
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_habit
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_habit();

CREATE TABLE tb_log_user_habit_day (

      id                    SERIAL PRIMARY KEY

    , user_habit_day_id     INTEGER
    , user_habit_id         INTEGER
    , day_of_week_id        INTEGER

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_user_habit_day()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_habit_day
        WHERE user_habit_day_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_user_habit_day
        WHERE user_habit_day_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_user_habit_day.';


        INSERT INTO tb_log_user_habit_day
        (
              user_habit_day_id
            , user_habit_id
            , day_of_week_id

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_habit_id
            , NEW.day_of_week_id

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_user_habit_day. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_user_habit_day
        (
              user_habit_day_id
            , user_habit_id
            , day_of_week_id

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_habit_id
            , NEW.day_of_week_id

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_user_habit_day.';


        INSERT INTO tb_log_user_habit_day
        (
              user_habit_day_id
            , user_habit_id
            , day_of_week_id

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.user_habit_id
            , OLD.day_of_week_id

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_user_habit_day
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_habit_day
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_habit_day();

CREATE TABLE tb_log_last_water_bill (

      id                    SERIAL PRIMARY KEY

    , last_water_bill_id    INTEGER
    , user_id               INTEGER
    , month                 DATE
    , total_value           NUMERIC(10,2)
    , m3_value              NUMERIC(10,2)

    , operation             VARCHAR(10) NOT NULL
    , executed_by           VARCHAR(100) NOT NULL
    , executed_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

    , previous_log_id       INTEGER
    , log_description       TEXT

);

CREATE OR REPLACE FUNCTION fn_log_last_water_bill()

RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

DECLARE

    field_name         TEXT;
    old_value          TEXT;
    new_value          TEXT;

    previous_log_id    INTEGER;

    log_description    TEXT;

BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT id
        INTO previous_log_id
        FROM tb_log_last_water_bill
        WHERE last_water_bill_id = NEW.id
        ORDER BY id DESC
        LIMIT 1;

    ELSE

        SELECT id
        INTO previous_log_id
        FROM tb_log_last_water_bill
        WHERE last_water_bill_id = OLD.id
        ORDER BY id DESC
        LIMIT 1;

    END IF;


    IF TG_OP = 'INSERT' THEN

        log_description :=
            'Registro inserido na tabela tb_last_water_bill.';


        INSERT INTO tb_log_last_water_bill
        (
              last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_id
            , NEW.month
            , NEW.total_value
            , NEW.m3_value

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

        log_description :=
            'Registro atualizado na tabela tb_last_water_bill. Campos alterados:';


        FOR field_name, old_value IN

            SELECT *
            FROM json_each_text(row_to_json(OLD))

        LOOP

            new_value := row_to_json(NEW) ->> field_name;


            IF old_value IS DISTINCT FROM new_value THEN

                log_description :=
                    log_description ||
                    E'\n- Campo: ' ||
                    field_name ||
                    ' | Valor antigo: "' ||
                    COALESCE(old_value, '<NULL>') ||
                    '" | Valor novo: "' ||
                    COALESCE(new_value, '<NULL>') ||
                    '"';

            END IF;

        END LOOP;


        INSERT INTO tb_log_last_water_bill
        (
              last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              NEW.id
            , NEW.user_id
            , NEW.month
            , NEW.total_value
            , NEW.m3_value

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

        log_description :=
            'Registro removido da tabela tb_last_water_bill.';


        INSERT INTO tb_log_last_water_bill
        (
              last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value

            , operation
            , executed_by
            , executed_at

            , previous_log_id
            , log_description
        )

        VALUES
        (
              OLD.id
            , OLD.user_id
            , OLD.month
            , OLD.total_value
            , OLD.m3_value

            , TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP

            , previous_log_id
            , log_description
        );


        RETURN OLD;

    END IF;

END;

$$;

CREATE TRIGGER trg_log_last_water_bill
AFTER INSERT OR UPDATE OR DELETE
ON tb_last_water_bill
FOR EACH ROW
EXECUTE FUNCTION fn_log_last_water_bill();