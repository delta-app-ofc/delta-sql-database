"""Aplica no banco JA PUBLICADO apenas o que mudou nos indicadores (sem apagar nada).

Diferente do setup_db.py, que recria o banco inteiro, este script e seguro para um
banco com dados: roda script-migration-indicadores.sql (idempotente), recarrega
silver e gold e, se pedido, carrega os dados de demonstracao da Swift.

Uso:
    python migrate_db.py                  # migracao + silver/gold
    python migrate_db.py --seed-swift     # tambem carrega a demonstracao
    python migrate_db.py --dry-run        # so mostra o plano e o banco alvo
"""

import argparse
import os
import sys

import psycopg2
from dotenv import load_dotenv

from setup_db import _connection_params, _find_env_file, _run_file

MIGRATION = "script-migration-indicadores.sql"
SEED = "script-dataload-swift.sql"
LOAD_CHAIN = "CALL silver.sp_load();\nCALL gold.sp_load();\n"
REQUIRED_SCHEMAS = ("stage", "silver", "gold", "dw")


def _missing_schemas(connection) -> list[str]:
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT schema_name FROM information_schema.schemata WHERE schema_name = ANY(%s)",
            (list(REQUIRED_SCHEMAS),),
        )
        found = {row[0] for row in cursor.fetchall()}
    return [name for name in REQUIRED_SCHEMAS if name not in found]


def _count_views(connection) -> int:
    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'dw'")
        return cursor.fetchone()[0]


def plan(seed_swift: bool) -> list[str]:
    steps = [MIGRATION, "silver.sp_load() + gold.sp_load()"]
    if seed_swift:
        steps.append(SEED)
    return steps


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Migracao dos indicadores no banco publicado.")
    parser.add_argument("--env-file", default=None, help="Arquivo .env com as variaveis DB_*.")
    parser.add_argument("--scripts-dir", default=None, help="Pasta com os scripts (padrao: a pasta deste arquivo).")
    parser.add_argument("--seed-swift", action="store_true", help="Carrega tambem a demonstracao da Swift (escreve no stage).")
    parser.add_argument("--dry-run", action="store_true", help="Mostra o plano e o banco alvo sem alterar nada.")
    parser.add_argument("--yes", action="store_true", help="Nao pede confirmacao.")
    arguments = parser.parse_args(argv)

    here = os.path.dirname(os.path.abspath(__file__))
    env_file = _find_env_file(here, arguments.env_file)
    if env_file:
        load_dotenv(env_file)
        print(f".env: {env_file}")
    else:
        print(".env nao encontrado; usando as variaveis do ambiente.")

    scripts_dir = arguments.scripts_dir or here
    params = _connection_params()
    steps = plan(arguments.seed_swift)
    print(f"Banco: {params['user']}@{params['host']}:{params['port']}/{params['dbname']}")
    print("Passos:", " -> ".join(steps))

    if arguments.dry_run:
        print("Dry-run: nada foi alterado.")
        return

    for name in (MIGRATION, SEED) if arguments.seed_swift else (MIGRATION,):
        if not os.path.isfile(os.path.join(scripts_dir, name)):
            sys.exit(f"Script nao encontrado: {os.path.join(scripts_dir, name)}")

    if not arguments.yes:
        answer = input("\nA migracao recria views e procedures dw/silver/gold (nao apaga dados). Digite 'sim' para continuar: ")
        if answer.strip().lower() != "sim":
            sys.exit("Cancelado.")

    connection = psycopg2.connect(**params)
    try:
        missing = _missing_schemas(connection)
        if missing:
            sys.exit(
                f"Faltam os schemas {', '.join(missing)}: este banco ainda nao tem o datamart. "
                "Rode primeiro o setup_db.py."
            )

        print(f"\n=== {MIGRATION} ===")
        _run_file(connection, os.path.join(scripts_dir, MIGRATION))
        print(f"[OK] {MIGRATION}")

        print("\n=== silver.sp_load() + gold.sp_load() ===")
        with connection.cursor() as cursor:
            cursor.execute(LOAD_CHAIN)
        connection.commit()
        print("[OK] carga silver/gold")

        if arguments.seed_swift:
            print(f"\n=== {SEED} ===")
            _run_file(connection, os.path.join(scripts_dir, SEED))
            print(f"[OK] {SEED}")

        print(f"\nViews no schema dw: {_count_views(connection)}")
        print("Migracao concluida.")
    except Exception as error:
        connection.rollback()
        print(f"[ERRO] {error}")
        raise SystemExit(1) from error
    finally:
        connection.close()


if __name__ == "__main__":
    main()
