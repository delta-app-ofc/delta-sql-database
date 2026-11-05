CREATE TABLE tb_property_goal (
      property_id                                 INTEGER       PRIMARY KEY
    , monthly_target_liters                       NUMERIC(12,2) NOT NULL
      CONSTRAINT chk_tb_property_goal_monthly_target_liters
        CHECK (monthly_target_liters > 0)
    , updated_at                                  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
    , CONSTRAINT fk_tb_property_goal_property     FOREIGN KEY (property_id)
        REFERENCES tb_property (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
