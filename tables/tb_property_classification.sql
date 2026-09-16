CREATE TABLE tb_property_classification (
      id                                                SERIAL      PRIMARY KEY
    , name                                              VARCHAR(50) NOT NULL UNIQUE
    , group_name                                        VARCHAR(20) NOT NULL
      CONSTRAINT chk_tb_property_classification_group   CHECK (group_name IN ('RESIDENCIAL', 'COMERCIAL'))
);
