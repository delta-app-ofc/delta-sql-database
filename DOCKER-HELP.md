# Docker — delta-sql-database

## Objetivo

Executar o smoke do schema em PostgreSQL descartável, sem carregar a configuração de backup.

## Pré-requisitos

Docker Engine em execução e Docker Compose v2. Execute os comandos na raiz deste repositório. Os exemplos usam uma identificação de projeto própria para isolar containers e volumes.

## Executar

```bash
docker compose -p delta-sql-test -f docker-compose.test.yml config --quiet
docker compose -p delta-sql-test -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from smoke
docker compose -p delta-sql-test -f docker-compose.test.yml down
```

## Conferir o resultado e encerrar

O runner deve terminar com código zero e a mensagem `Schema smoke checks passed.`. Falhas SQL interrompem a execução. Este fluxo não usa `.env`, não publica portas e não carrega dataload.

Para backup/setup, o arquivo é `docker-compose.yml`, que exige a configuração própria em `.env`. Não substitua esse arquivo pelo Compose de teste nem use o ambiente oficial para executar o smoke.

Para diagnosticar falhas de um serviço Compose, use `docker compose -p <projeto> -f <arquivo> ps -a` e `docker compose -p <projeto> -f <arquivo> logs <serviço>`, com o mesmo projeto e arquivo da execução.

`down` preserva volumes nomeados. Só use `down -v` depois de conferir o nome do projeto e confirmar que seus dados são descartáveis. Não remova volumes de outros ambientes.
