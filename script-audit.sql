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
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , region_id               INTEGER
    , name                    VARCHAR(20)
);

CREATE OR REPLACE FUNCTION fn_log_region()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS 
$$ 
BEGIN

    IF TG_OP = 'DELETE' THEN
        INSERT INTO tb_log_region
        (
              operation
            , executed_by
            , executed_at
            , region_id
            , name
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
        );

        RETURN OLD;
    
    ELSE 
        INSERT INTO tb_log_region
        (
              operation
            , executed_by
            , executed_at
            , region_id
            , name
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name 
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_region
AFTER INSERT OR UPDATE OR DELETE
ON tb_region
FOR EACH ROW
EXECUTE FUNCTION fn_log_region();

CREATE TABLE tb_log_day_of_week (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , day_of_week_id          INTEGER
    , name                    VARCHAR(20)
);

CREATE OR REPLACE FUNCTION fn_log_day_of_week()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_day_of_week
        (
              operation
            , executed_by
            , executed_at
            , day_of_week_id
            , name
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_day_of_week
        (
              operation
            , executed_by
            , executed_at
            , day_of_week_id
            , name
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_day_of_week
AFTER INSERT OR UPDATE OR DELETE
ON tb_day_of_week
FOR EACH ROW
EXECUTE FUNCTION fn_log_day_of_week();

CREATE TABLE tb_log_habit (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , habit_id                INTEGER
    , name                    VARCHAR(30)
    , description             TEXT
);

CREATE OR REPLACE FUNCTION fn_log_habit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_habit
        (
              operation
            , executed_by
            , executed_at
            , habit_id
            , name
            , description
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
            , OLD.description
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_habit
        (
              operation
            , executed_by
            , executed_at
            , habit_id
            , name
            , description
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
            , NEW.description
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_habit
AFTER INSERT OR UPDATE OR DELETE
ON tb_habit
FOR EACH ROW
EXECUTE FUNCTION fn_log_habit();

CREATE TABLE tb_log_address (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , address_id               INTEGER
    , region_id                INTEGER
    , cep                      CHAR(8)
    , city                     VARCHAR(60)
    , state                    VARCHAR(30)
);

CREATE OR REPLACE FUNCTION fn_log_address()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_address
        (
              operation
            , executed_by
            , executed_at
            , address_id
            , region_id
            , cep
            , city
            , state
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.region_id
            , OLD.cep
            , OLD.city
            , OLD.state
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_address
        (
              operation
            , executed_by
            , executed_at
            , address_id
            , region_id
            , cep
            , city
            , state
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.region_id
            , NEW.cep
            , NEW.city
            , NEW.state
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_address
AFTER INSERT OR UPDATE OR DELETE
ON tb_address
FOR EACH ROW
EXECUTE FUNCTION fn_log_address();

CREATE TABLE tb_log_user (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , user_id                 INTEGER
    , name                    VARCHAR(100)
    , email                   VARCHAR(255)
    , phone                   VARCHAR(15)
    , birth_date              DATE
    , registration_date       DATE
    , is_active               BOOLEAN
    , is_admin                BOOLEAN
    , is_manager              BOOLEAN
);

CREATE OR REPLACE FUNCTION fn_log_user()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user
        (
              operation
            , executed_by
            , executed_at
            , user_id
            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
            , OLD.email
            , OLD.phone
            , OLD.birth_date
            , OLD.registration_date
            , OLD.is_active
            , OLD.is_admin
            , OLD.is_manager
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user
        (
              operation
            , executed_by
            , executed_at
            , user_id
            , name
            , email
            , phone
            , birth_date
            , registration_date
            , is_active
            , is_admin
            , is_manager
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
            , NEW.email
            , NEW.phone
            , NEW.birth_date
            , NEW.registration_date
            , NEW.is_active
            , NEW.is_admin
            , NEW.is_manager
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_user
AFTER INSERT OR UPDATE OR DELETE
ON tb_user
FOR EACH ROW
EXECUTE FUNCTION fn_log_user();

CREATE TABLE tb_log_property (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , property_id             INTEGER
    , name                    VARCHAR(100)
    , type                    VARCHAR(20)
    , classification          VARCHAR(20)
    , address_id              INTEGER
    , registration_date       DATE
);

CREATE OR REPLACE FUNCTION fn_log_property()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_property
        (
              operation
            , executed_by
            , executed_at
            , property_id
            , name
            , type
            , classification
            , address_id
            , registration_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.name
            , OLD.type
            , OLD.classification
            , OLD.address_id
            , OLD.registration_date
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_property
        (
              operation
            , executed_by
            , executed_at
            , property_id
            , name
            , type
            , classification
            , address_id
            , registration_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.name
            , NEW.type
            , NEW.classification
            , NEW.address_id
            , NEW.registration_date
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_property
AFTER INSERT OR UPDATE OR DELETE
ON tb_property
FOR EACH ROW
EXECUTE FUNCTION fn_log_property();

CREATE TABLE tb_log_user_property (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , user_property_id        INTEGER
    , user_id                 INTEGER
    , property_id             INTEGER
    , association_date        DATE
);

CREATE OR REPLACE FUNCTION fn_log_user_property()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user_property
        (
              operation
            , executed_by
            , executed_at
            , user_property_id
            , user_id
            , property_id
            , association_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_id
            , OLD.property_id
            , OLD.association_date
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user_property
        (
              operation
            , executed_by
            , executed_at
            , user_property_id
            , user_id
            , property_id
            , association_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_id
            , NEW.property_id
            , NEW.association_date
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_user_property
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_property
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_property();

CREATE TABLE tb_log_device (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , id_device               INTEGER
    , device_id               INTEGER
    , property_id             INTEGER
    , is_active               BOOLEAN
    , installation_date       DATE
);

CREATE OR REPLACE FUNCTION fn_log_device()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_device
        (
              operation
            , executed_by
            , executed_at
            , id_device
            , device_id
            , property_id
            , is_active
            , installation_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.device_id
            , OLD.property_id
            , OLD.is_active
            , OLD.installation_date
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_device
        (
              operation
            , executed_by
            , executed_at
            , id_device
            , device_id
            , property_id
            , is_active
            , installation_date
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.device_id
            , NEW.property_id
            , NEW.is_active
            , NEW.installation_date
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_device
AFTER INSERT OR UPDATE OR DELETE
ON tb_device
FOR EACH ROW
EXECUTE FUNCTION fn_log_device();

CREATE TABLE tb_log_region_rate (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , region_rate_id          INTEGER
    , region_id               INTEGER
    , m3_value                NUMERIC(10,2)
    , initial_validity        DATE
    , final_validity          DATE
);

CREATE OR REPLACE FUNCTION fn_log_region_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_region_rate
        (
              operation
            , executed_by
            , executed_at
            , region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.region_id
            , OLD.m3_value
            , OLD.initial_validity
            , OLD.final_validity
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_region_rate
        (
              operation
            , executed_by
            , executed_at
            , region_rate_id
            , region_id
            , m3_value
            , initial_validity
            , final_validity
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.region_id
            , NEW.m3_value
            , NEW.initial_validity
            , NEW.final_validity
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_region_rate
AFTER INSERT OR UPDATE OR DELETE
ON tb_region_rate
FOR EACH ROW
EXECUTE FUNCTION fn_log_region_rate();

CREATE TABLE tb_log_user_habit (
      id                      SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , user_habit_id           INTEGER
    , user_id                 INTEGER
    , habit_id                INTEGER
    , frequency               INTEGER
);

CREATE OR REPLACE FUNCTION fn_log_user_habit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user_habit
        (
              operation
            , executed_by
            , executed_at
            , user_habit_id
            , user_id
            , habit_id
            , frequency
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_id
            , OLD.habit_id
            , OLD.frequency
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user_habit
        (
              operation
            , executed_by
            , executed_at
            , user_habit_id
            , user_id
            , habit_id
            , frequency
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_id
            , NEW.habit_id
            , NEW.frequency
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_user_habit
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_habit
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_habit();

CREATE TABLE tb_log_user_habit_day (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , user_habit_day_id       INTEGER
    , user_habit_id           INTEGER
    , day_of_week_id          INTEGER
);

CREATE OR REPLACE FUNCTION fn_log_user_habit_day()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user_habit_day
        (
              operation
            , executed_by
            , executed_at
            , user_habit_day_id
            , user_habit_id
            , day_of_week_id
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_habit_id
            , OLD.day_of_week_id
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_user_habit_day
        (
              operation
            , executed_by
            , executed_at
            , user_habit_day_id
            , user_habit_id
            , day_of_week_id
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_habit_id
            , NEW.day_of_week_id
        );

        RETURN NEW;

    END IF;

END;
$$;

CREATE TRIGGER trg_log_user_habit_day
AFTER INSERT OR UPDATE OR DELETE
ON tb_user_habit_day
FOR EACH ROW
EXECUTE FUNCTION fn_log_user_habit_day();

CREATE TABLE tb_log_last_water_bill (
      id                  SERIAL       PRIMARY KEY
    , operation               VARCHAR(10)  NOT NULL
    , executed_by             VARCHAR(100) NOT NULL
    , executed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    , last_water_bill_id      INTEGER
    , user_id                 INTEGER
    , month                   DATE
    , total_value             NUMERIC(10,2)
    , m3_value                NUMERIC(10,2)
);

CREATE OR REPLACE FUNCTION fn_log_last_water_bill()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_last_water_bill
        (
              operation
            , executed_by
            , executed_at
            , last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , OLD.id
            , OLD.user_id
            , OLD.month
            , OLD.total_value
            , OLD.m3_value
        );

        RETURN OLD;

    ELSE

        INSERT INTO tb_log_last_water_bill
        (
              operation
            , executed_by
            , executed_at
            , last_water_bill_id
            , user_id
            , month
            , total_value
            , m3_value
        )
        VALUES
        (
              TG_OP
            , CURRENT_USER
            , CURRENT_TIMESTAMP
            , NEW.id
            , NEW.user_id
            , NEW.month
            , NEW.total_value
            , NEW.m3_value
        );

        RETURN NEW;

    END IF;

END;
$$;


CREATE TRIGGER trg_log_last_water_bill
AFTER INSERT OR UPDATE OR DELETE
ON tb_last_water_bill
FOR EACH ROW
EXECUTE FUNCTION fn_log_last_water_bill();