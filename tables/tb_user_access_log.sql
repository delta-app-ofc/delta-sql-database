CREATE TABLE tb_user_access_log (

      id                    SERIAL       PRIMARY KEY
    , user_id               INTEGER      NOT NULL

    , access_channel        VARCHAR(20)
      CONSTRAINT chk_tb_user_access_log_access_channel
          CHECK (access_channel IN ('WEB', 'MOBILE', 'CHATBOT'))

    , accessed_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP

    , CONSTRAINT fk_tb_user_access_log_user
        FOREIGN KEY (user_id)
        REFERENCES tb_user (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
