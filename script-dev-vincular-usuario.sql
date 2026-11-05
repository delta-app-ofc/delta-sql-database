-- ============================================================
-- SO PARA AMBIENTE LOCAL / DEMONSTRACAO
-- Vincula uma conta ja criada (cadastro normal da plataforma) a organizacao
-- SWIFT do script-dataload-swift.sql, para que o dashboard e as demais telas
-- mostrem os dados da demonstracao com esse login.
--
-- Uso:  psql -d <banco> -v email='seu@email.com' -f script-dev-vincular-usuario.sql
-- Idempotente. Nao rode em producao.
-- ============================================================
\set ON_ERROR_STOP on

BEGIN;

SELECT EXISTS (SELECT 1 FROM tb_user WHERE UPPER(email) = UPPER(:'email')) AS user_exists,
       EXISTS (SELECT 1 FROM tb_property p JOIN tb_organization o ON o.id = p.organization_id
               WHERE o.cnpj = '12345678000190') AS seed_exists
\gset
\if :user_exists
\else
  DO $$ BEGIN RAISE EXCEPTION 'Conta nao encontrada. Crie a conta pelo cadastro antes de vincular.'; END $$;
\endif
\if :seed_exists
\else
  DO $$ BEGIN RAISE EXCEPTION 'Dados Swift ausentes. Carregue o seed local antes de vincular.'; END $$;
\endif

INSERT INTO tb_user_organization (user_id, organization_id)
SELECT u.id, o.id
FROM tb_user u
CROSS JOIN tb_organization o
WHERE UPPER(u.email) = UPPER(:'email')
  AND o.cnpj = '12345678000190'
ON CONFLICT (user_id, organization_id) DO NOTHING;

INSERT INTO tb_user_property (user_id, property_id)
SELECT u.id, p.id
FROM tb_user u
JOIN tb_organization o ON o.cnpj = '12345678000190'
JOIN tb_property p ON p.organization_id = o.id
WHERE UPPER(u.email) = UPPER(:'email')
ON CONFLICT (user_id, property_id) DO NOTHING;

COMMIT;

SELECT u.email, COUNT(up.property_id) AS unidades_vinculadas
FROM tb_user u
LEFT JOIN tb_user_property up ON up.user_id = u.id
WHERE UPPER(u.email) = UPPER(:'email')
GROUP BY u.email;
