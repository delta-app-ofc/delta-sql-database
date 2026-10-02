CREATE TABLE tb_organization (
      id                                        SERIAL       PRIMARY KEY
    , corporate_name                            VARCHAR(150) NOT NULL
    , trade_name                                VARCHAR(150) NOT NULL
    , cnpj                                       CHAR(14)     NOT NULL
      CONSTRAINT chk_tb_organization_cnpj CHECK (cnpj ~ '^[0-9]{14}$')
    , business_segment                          VARCHAR(20)  NOT NULL
      CONSTRAINT chk_tb_organization_business_segment
        CHECK (business_segment IN ('VAREJO', 'INDUSTRIA', 'CONDOMINIO', 'FACILITIES'))
    , declared_unit_count                       INTEGER
      CONSTRAINT chk_tb_organization_declared_unit_count
        CHECK (declared_unit_count IS NULL OR declared_unit_count > 0)
    , registration_date                         DATE         NOT NULL DEFAULT CURRENT_DATE
    , CONSTRAINT uq_tb_organization_cnpj                     UNIQUE (cnpj)
);
