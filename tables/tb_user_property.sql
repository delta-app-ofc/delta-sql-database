CREATE TABLE tb_user_property (
      id                                      SERIAL      PRIMARY KEY
    , user_id                                 INTEGER     NOT NULL
    , property_id                             INTEGER     NOT NULL
    , association_date                        DATE        NOT NULL DEFAULT CURRENT_DATE
    , CONSTRAINT uq_tb_user_property          UNIQUE     (user_id, property_id)
    , CONSTRAINT fk_tb_user_property_user     FOREIGN KEY (user_id)
        REFERENCES tb_user (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_user_property_property FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);