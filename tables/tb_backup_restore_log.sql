CREATE TABLE tb_backup_restore_log (

      id                       SERIAL      PRIMARY KEY

    , started_at               TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
    , finished_at              TIMESTAMP

    , status                   VARCHAR(10) NOT NULL DEFAULT 'RUNNING'
      CONSTRAINT chk_tb_backup_restore_log_status
          CHECK (status IN ('RUNNING', 'SUCCESS', 'ERROR'))

    , table_name               VARCHAR(60) NOT NULL

    , expected_row_count       INTEGER
      CONSTRAINT chk_tb_backup_restore_log_expected_row_count  CHECK (expected_row_count >= 0)

    , restored_row_count       INTEGER
      CONSTRAINT chk_tb_backup_restore_log_restored_row_count  CHECK (restored_row_count >= 0)

    , note                     TEXT
);
