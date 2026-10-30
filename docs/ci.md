# CI PostgreSQL

A cada pull request e por execução manual, o workflow executa o smoke test em um PostgreSQL 16 descartável com Docker Compose. Ele carrega os scripts de schema, otimização, auditoria e roles nessa ordem. O teste verifica duas tabelas, a existência de uma chave estrangeira e da função `fn_user_is_active`, além de exercitar a constraint de região com um valor válido e outro inválido.

Para executar localmente com Docker e Compose disponíveis:

```sh
docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from smoke
docker compose -f docker-compose.test.yml down --volumes --remove-orphans
```

O banco é temporário e não usa credenciais de produção. Esse smoke test não cobre todas as funções, procedures, triggers, permissões ou a carga `script-dataload.sql` e não substitui testes completos de integração.
