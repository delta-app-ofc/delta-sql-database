CREATE TABLE tb_property_classification (
      id                                                SERIAL      PRIMARY KEY
    , name                                              VARCHAR(50) NOT NULL UNIQUE
      CONSTRAINT chk_tb_property_classification_name
        CHECK (name IN ('RESIDENCIAL_NORMAL', 'RESIDENCIAL_SOCIAL', 'RESIDENCIAL_FAVELA', 'RESIDENCIAL_ESPECIAL', 'COMERCIAL_NORMAL_INDUSTRIAL', 'COMERCIAL_ESPECIAL', 'COMERCIAL_ENTIDADE_ASSISTENCIA_SOCIAL', 'PUBLICA_COM_CONTRATO'))
    , group_name                                        VARCHAR(20) NOT NULL
      CONSTRAINT chk_tb_property_classification_group   CHECK (group_name IN ('RESIDENCIAL', 'COMERCIAL'))
);
