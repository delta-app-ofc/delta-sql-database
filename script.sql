-- =========================================
-- DROP TABLE IF EXISTS
-- =========================================

DROP TABLE IF EXISTS tbl_usuario_habito;
DROP TABLE IF EXISTS tbl_habito;
DROP TABLE IF EXISTS tbl_alerta;
DROP TABLE IF EXISTS tbl_meta_consumo;
DROP TABLE IF EXISTS tbl_dispositivo;
DROP TABLE IF EXISTS tbl_usuario_instalacao;
DROP TABLE IF EXISTS tbl_instalacao;
DROP TABLE IF EXISTS tbl_usuario;
DROP TABLE IF EXISTS tbl_tarifa_agua;

-- =========================================
-- TABELA USUÁRIO
-- =========================================

CREATE TABLE tbl_usuario (
      id               SERIAL          PRIMARY KEY
    , nome             VARCHAR(100)    NOT NULL
    , email            VARCHAR(255)    NOT NULL UNIQUE
    , senha            VARCHAR(255)    NOT NULL
    , telefone         VARCHAR(20)
    , data_nascimento  DATE            NOT NULL
    , data_cadastro    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
    , ativo            BOOLEAN         NOT NULL DEFAULT TRUE
);

-- =========================================
-- TABELA INSTALAÇÃO
-- =========================================

CREATE TABLE tbl_instalacao (
      id                   SERIAL          PRIMARY KEY
    , nome_identificador   VARCHAR(100)    NOT NULL
    , tipo_classificacao   VARCHAR(20)     NOT NULL
    , tipo_imovel          VARCHAR(30)     NOT NULL
    , percentual_consumo   NUMERIC(5,2)    NOT NULL
    , cep                  VARCHAR(9)      NOT NULL
    , cidade               VARCHAR(100)    NOT NULL
    , estado               CHAR(2)         NOT NULL
    , data_cadastro        TIMESTAMP       DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT chk_tipo_classificacao
        CHECK (tipo_classificacao IN ('residencial', 'comercial'))

    , CONSTRAINT chk_percentual_consumo
        CHECK (percentual_consumo BETWEEN 0 AND 100)
);

-- =========================================
-- TABELA USUÁRIO x INSTALAÇÃO
-- =========================================

CREATE TABLE tbl_usuario_instalacao (
      id               SERIAL          PRIMARY KEY
    , id_usuario       INTEGER         NOT NULL
    , id_instalacao    INTEGER         NOT NULL
    , data_vinculo     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT fk_usuario_instalacao_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES tbl_usuario(id)
        ON DELETE CASCADE

    , CONSTRAINT fk_usuario_instalacao_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE

    , CONSTRAINT uq_usuario_instalacao
        UNIQUE (id_usuario, id_instalacao)
);

-- =========================================
-- TABELA DISPOSITIVO
-- =========================================

CREATE TABLE tbl_dispositivo (
      id                   SERIAL          PRIMARY KEY
    , device_id            VARCHAR(80)    NOT NULL UNIQUE
    , id_instalacao        INTEGER         NOT NULL
    , ativo                BOOLEAN         NOT NULL DEFAULT TRUE
    , data_instalacao      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
    , ultima_comunicacao   TIMESTAMP

    , CONSTRAINT fk_dispositivo_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE
);

-- =========================================
-- TABELA META CONSUMO
-- =========================================

CREATE TABLE tbl_meta_consumo (
      id                     SERIAL          PRIMARY KEY
    , id_instalacao          INTEGER         NOT NULL
    , limite_diario_litros   NUMERIC(10,2)
    , limite_mensal_litros   NUMERIC(10,2)
    , data_inicio            DATE            NOT NULL
    , data_fim               DATE

    , CONSTRAINT fk_meta_consumo_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE

    , CONSTRAINT chk_limite_diario
        CHECK (limite_diario_litros IS NULL OR limite_diario_litros > 0)

    , CONSTRAINT chk_limite_mensal
        CHECK (limite_mensal_litros IS NULL OR limite_mensal_litros > 0)

    , CONSTRAINT chk_periodo_meta
        CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- =========================================
-- TABELA ALERTA
-- =========================================

CREATE TABLE tbl_alerta (
      id               SERIAL          PRIMARY KEY
    , id_instalacao    INTEGER         NOT NULL
    , tipo             VARCHAR(30)     NOT NULL
    , mensagem         VARCHAR(500)    NOT NULL
    , status           VARCHAR(20)     NOT NULL DEFAULT 'ativo'
    , data_criacao     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
    , data_resolucao   TIMESTAMP

    , CONSTRAINT fk_alerta_instalacao
        FOREIGN KEY (id_instalacao)
        REFERENCES tbl_instalacao(id)
        ON DELETE CASCADE

    , CONSTRAINT chk_tipo_alerta
        CHECK (tipo IN ('vazamento', 'consumo_alto', 'consumo_baixo', 'dispositivo_offline'))

    , CONSTRAINT chk_status_alerta
        CHECK (status IN ('ativo', 'resolvido'))

    , CONSTRAINT chk_data_resolucao
        CHECK (data_resolucao IS NULL OR data_resolucao >= data_criacao)
);

-- =========================================
-- TABELA TARIFA ÁGUA
-- =========================================

CREATE TABLE tbl_tarifa_agua (
      id               SERIAL          PRIMARY KEY
    , cidade           VARCHAR(100)    NOT NULL
    , faixa_inicial    NUMERIC(10,2)   NOT NULL
    , faixa_final      NUMERIC(10,2)   NOT NULL
    , valor_m3         NUMERIC(10,2)   NOT NULL
    , vigencia_inicio  DATE            NOT NULL
    , vigencia_fim     DATE

    , CONSTRAINT chk_faixa_consumo
        CHECK (faixa_inicial >= 0 AND faixa_final > faixa_inicial)

    , CONSTRAINT chk_valor_m3
        CHECK (valor_m3 > 0)

    , CONSTRAINT chk_vigencia
        CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio)
);

-- =========================================
-- TABELA HÁBITO
-- =========================================

CREATE TABLE tbl_habito (
      id        SERIAL          PRIMARY KEY
    , codigo    VARCHAR(50)     NOT NULL UNIQUE
    , descricao TEXT            NOT NULL
);

-- =========================================
-- TABELA USUÁRIO x HÁBITO
-- =========================================

CREATE TABLE tbl_usuario_habito (
      id             SERIAL          PRIMARY KEY
    , id_usuario     INTEGER         NOT NULL
    , id_habito      INTEGER         NOT NULL
    , data_vinculo   TIMESTAMP       DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT fk_usuario_habito_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES tbl_usuario(id)
        ON DELETE CASCADE

    , CONSTRAINT fk_usuario_habito_habito
        FOREIGN KEY (id_habito)
        REFERENCES tbl_habito(id)
        ON DELETE CASCADE

    , CONSTRAINT uq_usuario_habito
        UNIQUE (id_usuario, id_habito)
);