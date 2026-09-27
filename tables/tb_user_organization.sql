CREATE TABLE tb_user_organization (
      id                                          SERIAL      PRIMARY KEY
    , user_id                                     INTEGER     NOT NULL
    , organization_id                             INTEGER     NOT NULL
    , association_date                            DATE        NOT NULL DEFAULT CURRENT_DATE
    , CONSTRAINT uq_tb_user_organization           UNIQUE     (user_id, organization_id)
    , CONSTRAINT fk_tb_user_organization_user      FOREIGN KEY (user_id)
        REFERENCES tb_user (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT fk_tb_user_organization_org       FOREIGN KEY (organization_id)
        REFERENCES tb_organization (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
