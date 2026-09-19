CREATE TABLE tb_log_rpa (

      id                       SERIAL      PRIMARY KEY

    , started_at               TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
    , finished_at              TIMESTAMP

    , status                   VARCHAR(10) NOT NULL DEFAULT 'RUNNING'
      CONSTRAINT chk_tb_log_rpa_status
          CHECK (status IN ('RUNNING', 'SUCCESS', 'ERROR'))

    , inserted_count           INTEGER     NOT NULL DEFAULT 0
      CONSTRAINT chk_tb_log_rpa_inserted_count          CHECK (inserted_count >= 0)

    , updated_count            INTEGER     NOT NULL DEFAULT 0
      CONSTRAINT chk_tb_log_rpa_updated_count           CHECK (updated_count >= 0)

    , deleted_count            INTEGER     NOT NULL DEFAULT 0
      CONSTRAINT chk_tb_log_rpa_deleted_count           CHECK (deleted_count >= 0)

    , validation_error_count   INTEGER     NOT NULL DEFAULT 0
      CONSTRAINT chk_tb_log_rpa_validation_error_count  CHECK (validation_error_count >= 0)

    , error_message            TEXT
);
