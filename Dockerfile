FROM python:3.12-slim

# O cliente do repositorio padrao do Debian fica atras da versao do Postgres
# do Neon (hoje, versao 18) - pg_dump/pg_restore recusam rodar contra um
# servidor mais novo que o cliente. Instala direto do repositorio oficial
# do Postgres pra garantir a versao certa.
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends curl gnupg lsb-release ca-certificates \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends postgresql-client-18 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
