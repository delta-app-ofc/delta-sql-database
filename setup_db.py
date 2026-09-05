#!/usr/bin/env python3
"""
Roda os scripts SQL do delta-database.

Ordem padrao:
    script-schema.sql -> script-optimization.sql -> script-audit.sql
    -> script-roles.sql -> script-dataload.sql
"""

import argparse
import os
import sys

import psycopg2
from dotenv import load_dotenv


SCRIPTS = [
    "script-schema.sql",
    "script-optimization.sql",
    "script-audit.sql",
    "script-roles.sql",
    "script-dataload.sql",
]


def _find_env_file(here: str, given: str | None) -> str | None:
    if given:
        return given

    candidates = [
        os.path.join(here, ".env"),
        os.path.join(here, "..", "..", "delta-rpa", ".env"),
    ]

    for candidate in candidates:
        if os.path.isfile(candidate):
            return candidate

    return None


def _connection_params() -> dict:
    host = os.getenv("SECOND_YEAR_DB_HOST", "")
    name = os.getenv("SECOND_YEAR_DB_NAME", "")
    user = os.getenv("SECOND_YEAR_DB_USER", "")

    if not host or not name or not user:
        sys.exit(
            "Faltam variaveis SECOND_YEAR_DB_HOST / _NAME / _USER. "
            "Confira o .env."
        )

    return {
        "host": host,
        "port": os.getenv("SECOND_YEAR_DB_PORT", "5432"),
        "dbname": name,
        "user": user,
        "password": os.getenv("SECOND_YEAR_DB_PASSWORD", ""),
        "sslmode": os.getenv("SECOND_YEAR_DB_SSLMODE", "prefer"),
    }


def _run_file(connection, path: str) -> None:
    with open(path, encoding="utf-8") as sql_file:
        sql = sql_file.read()

    with connection.cursor() as cursor:
        cursor.execute(sql)

    for notice in connection.notices[-8:]:
        print("   " + notice.strip())
    connection.notices.clear()

    connection.commit()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Setup do banco do Segundo Ano (delta-database)."
    )
    parser.add_argument(
        "--env-file",
        default=None,
        help="Arquivo .env com as variaveis SECOND_YEAR_DB_*."
    )
    parser.add_argument(
        "--scripts-dir",
        default=None,
        help="Pasta com os script-*.sql (padrao: a pasta deste arquivo)."
    )
    parser.add_argument(
        "--only",
        action="append",
        default=None,
        help="Roda apenas o(s) script(s) informado(s). Pode repetir."
    )
    parser.add_argument(
        "--skip",
        action="append",
        default=[],
        help="Nao roda o(s) script(s) informado(s). Pode repetir."
    )
    parser.add_argument(
        "--continue-on-error",
        action="store_true",
        help="Nao para no primeiro erro (util em reexecucao)."
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Nao pede confirmacao (script-schema.sql APAGA todas as tabelas)."
    )
    arguments = parser.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))

    env_file = _find_env_file(here, arguments.env_file)
    if env_file:
        load_dotenv(env_file)
        print(f".env: {env_file}")
    else:
        print(".env nao encontrado; usando as variaveis do ambiente.")

    scripts_dir = arguments.scripts_dir or here
    planned = arguments.only or SCRIPTS
    planned = [name for name in planned if name not in arguments.skip]

    params = _connection_params()
    print(
        f"Banco: {params['user']}@{params['host']}:"
        f"{params['port']}/{params['dbname']}"
    )
    print("Scripts:", ", ".join(planned))

    if not arguments.yes and "script-schema.sql" in planned:
        answer = input(
            "\nscript-schema.sql APAGA todas as tabelas. "
            "Digite 'sim' para continuar: "
        )
        if answer.strip().lower() != "sim":
            sys.exit("Cancelado.")

    connection = psycopg2.connect(**params)

    failures = 0

    try:
        for name in planned:
            path = os.path.join(scripts_dir, name)

            if not os.path.isfile(path):
                print(f"\n[PULADO] {name} (nao encontrado em {scripts_dir})")
                continue

            print(f"\n=== {name} ===")

            try:
                _run_file(connection, path)
                print(f"[OK] {name}")

            except Exception as error:
                failures += 1
                connection.rollback()
                print(f"[ERRO] {name}: {error}")

                if not arguments.continue_on_error:
                    sys.exit(1)

    finally:
        connection.close()

    if failures:
        print(f"\nConcluido com {failures} erro(s).")
        sys.exit(1)

    print("\nTudo rodou com sucesso.")


if __name__ == "__main__":
    main()
