"""
Backup e teste de restauracao do delta-database.

Ver DADOS/SQL/backup-recuperacao.md no delta-handbook para o procedimento
completo de backup e recuperacao de falhas. 

Se quiser rodar local:

docker compose run --rm tools python backup_db.py backup
docker compose run --rm tools python backup_db.py restore-test --yes
"""

import argparse
import glob
import json
import os
import subprocess
import sys
import time
from datetime import datetime

import psycopg2
from dotenv import load_dotenv


def _find_env_file(here: str, given: str | None) -> str | None:
    if given:
        return given

    candidate = os.path.join(here, ".env")
    if os.path.isfile(candidate):
        return candidate

    return None


def _connection_params(prefix: str) -> dict:
    host = os.getenv(f"{prefix}_HOST", "")
    name = os.getenv(f"{prefix}_NAME", "")
    user = os.getenv(f"{prefix}_USER", "")

    if not host or not name or not user:
        sys.exit(
            f"Faltam variaveis {prefix}_HOST / {prefix}_NAME / {prefix}_USER. "
            "Confira o .env."
        )

    return {
        "host": host,
        "port": os.getenv(f"{prefix}_PORT", "5432"),
        "dbname": name,
        "user": user,
        "password": os.getenv(f"{prefix}_PASSWORD", ""),
        "sslmode": os.getenv(f"{prefix}_SSLMODE", "prefer"),
    }


def _pg_env(params: dict) -> dict:
    env = os.environ.copy()
    env["PGHOST"] = params["host"]
    env["PGPORT"] = str(params["port"])
    env["PGDATABASE"] = params["dbname"]
    env["PGUSER"] = params["user"]
    env["PGPASSWORD"] = params["password"]
    env["PGSSLMODE"] = params["sslmode"]
    return env


def _count_rows(params: dict) -> dict:
    connection = psycopg2.connect(**params)

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                  AND table_name LIKE 'tb\\_%' ESCAPE '\\'
                ORDER BY table_name
                """
            )
            tables = [row[0] for row in cursor.fetchall()]

            counts = {}
            for table in tables:
                cursor.execute(f'SELECT count(*) FROM "{table}"')
                counts[table] = cursor.fetchone()[0]

        return counts
    finally:
        connection.close()


def _default_manifest_path(dump_path: str) -> str:
    base, _ = os.path.splitext(dump_path)
    return f"{base}.manifest.json"


def _latest_dump(backups_dir: str) -> str:
    candidates = glob.glob(os.path.join(backups_dir, "*.dump"))
    if not candidates:
        sys.exit(f"[ERRO] Nenhum .dump encontrado em {backups_dir}/.")

    return max(candidates, key=os.path.getmtime)


def _cleanup_old_backups(backups_dir: str, days: int) -> None:
    cutoff = time.time() - (days * 86400)
    removed = 0

    for name in os.listdir(backups_dir):
        path = os.path.join(backups_dir, name)
        if os.path.isfile(path) and os.path.getmtime(path) < cutoff:
            os.remove(path)
            removed += 1

    print(f"[OK] Limpeza: {removed} arquivo(s) com mais de {days} dia(s) removido(s).")


def _log_results(params: dict, started_at: datetime, finished_at: datetime, results: list) -> None:
    connection = psycopg2.connect(**params)

    try:
        with connection.cursor() as cursor:
            for table, expected, restored, ok in results:
                cursor.execute(
                    """
                    INSERT INTO tb_backup_restore_log
                        (started_at, finished_at, status, table_name,
                         expected_row_count, restored_row_count, note)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        started_at,
                        finished_at,
                        "SUCCESS" if ok else "ERROR",
                        table,
                        expected,
                        restored,
                        "restore-test via backup_db.py",
                    ),
                )
        connection.commit()
    finally:
        connection.close()

    print(f"[OK] {len(results)} linha(s) registrada(s) em tb_backup_restore_log.")


def cmd_backup(arguments: argparse.Namespace) -> None:
    params = _connection_params("DB")
    print(f"Banco: {params['user']}@{params['host']}:{params['port']}/{params['dbname']}")

    backups_dir = arguments.backups_dir
    os.makedirs(backups_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M")
    base_name = f"delta_{timestamp}"
    dump_path = os.path.join(backups_dir, f"{base_name}.dump")
    manifest_path = os.path.join(backups_dir, f"{base_name}.manifest.json")

    command = ["pg_dump", "--format=custom", f"--file={dump_path}"]
    for table in arguments.only_table or []:
        command.append(f"--table={table}")

    print("Rodando pg_dump...")
    try:
        subprocess.run(command, env=_pg_env(params), check=True)
    except subprocess.CalledProcessError as error:
        sys.exit(f"[ERRO] pg_dump falhou: {error}")
    except FileNotFoundError:
        sys.exit("[ERRO] pg_dump nao encontrado. Instale o cliente do PostgreSQL.")

    print(f"[OK] Dump criado: {dump_path}")

    manifest = {
        "generated_at": datetime.now().isoformat(),
        "source": f"{params['host']}:{params['port']}/{params['dbname']}",
        "tables": _count_rows(params),
    }
    with open(manifest_path, "w", encoding="utf-8") as manifest_file:
        json.dump(manifest, manifest_file, indent=2, ensure_ascii=False)

    print(f"[OK] Manifesto criado: {manifest_path}")
    for table, count in manifest["tables"].items():
        print(f"   {table}: {count} linha(s)")

    if arguments.cleanup_days is not None:
        _cleanup_old_backups(backups_dir, arguments.cleanup_days)


def cmd_restore_test(arguments: argparse.Namespace) -> None:
    dump_path = arguments.dump or _latest_dump(arguments.backups_dir)
    print(f"Dump: {dump_path}")

    if not os.path.isfile(dump_path):
        sys.exit(f"[ERRO] Dump nao encontrado: {dump_path}")

    manifest_path = arguments.manifest or _default_manifest_path(dump_path)
    if not os.path.isfile(manifest_path):
        sys.exit(f"[ERRO] Manifesto nao encontrado: {manifest_path}")

    with open(manifest_path, encoding="utf-8") as manifest_file:
        manifest = json.load(manifest_file)

    test_params = _connection_params("TEST_DB")
    print(
        f"Banco de teste: {test_params['user']}@{test_params['host']}:"
        f"{test_params['port']}/{test_params['dbname']}"
    )

    if not arguments.yes:
        answer = input(
            f"\nIsso APAGA e recria os objetos existentes em "
            f"{test_params['dbname']}@{test_params['host']}. "
            "Digite 'sim' para continuar: "
        )
        if answer.strip().lower() != "sim":
            sys.exit("Cancelado.")

    started_at = datetime.now()

    command = [
        "pg_restore",
        f"--dbname={test_params['dbname']}",
        "--clean",
        "--if-exists",
        dump_path,
    ]

    print("Rodando pg_restore...")
    try:
        result = subprocess.run(command, env=_pg_env(test_params))
    except FileNotFoundError:
        sys.exit("[ERRO] pg_restore nao encontrado. Instale o cliente do PostgreSQL.")

    if result.returncode != 0:
        print(
            f"[AVISO] pg_restore terminou com codigo {result.returncode}. Isso "
            "acontece mesmo em restauracoes bem-sucedidas quando o cliente e o "
            "servidor sao de versoes diferentes (avisos que o pg_restore trata "
            "como erro, mas nao impedem a restauracao). A contagem de linhas "
            "abaixo e o criterio real de sucesso, nao o codigo de saida."
        )

    print("Conferindo contagens...")

    restored_counts = _count_rows(test_params)
    expected_counts = manifest["tables"]

    results = []
    all_ok = True
    for table, expected in expected_counts.items():
        restored = restored_counts.get(table)
        ok = restored == expected
        all_ok = all_ok and ok
        results.append((table, expected, restored, ok))
        marker = "OK" if ok else "FALHA"
        print(f"   [{marker}] {table}: esperado={expected} restaurado={restored}")

    finished_at = datetime.now()

    real_params = _connection_params("DB")
    _log_results(real_params, started_at, finished_at, results)

    if not all_ok:
        sys.exit(1)

    print("\nTeste de restauracao OK: todas as tabelas bateram.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Backup logico e teste de restauracao do delta-database."
    )
    parser.add_argument(
        "--env-file",
        default=None,
        help="Arquivo .env com as variaveis DB_*/TEST_DB_*."
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    backup_parser = subparsers.add_parser(
        "backup", help="Faz backup logico (pg_dump) do banco DB_*."
    )
    backup_parser.add_argument(
        "--backups-dir",
        default="backups",
        help="Pasta onde salvar o dump e o manifesto (padrao: backups/)."
    )
    backup_parser.add_argument(
        "--cleanup-days",
        type=int,
        default=None,
        help="Apaga dumps mais antigos que N dias na pasta de backups."
    )
    backup_parser.add_argument(
        "--only-table",
        action="append",
        default=None,
        help="Limita o pg_dump a essa(s) tabela(s). Pode repetir. "
             "Usado pra simular um dump incompleto em teste."
    )

    restore_parser = subparsers.add_parser(
        "restore-test",
        help="Restaura um dump no banco TEST_DB_* e confere as contagens."
    )
    restore_parser.add_argument(
        "--dump",
        default=None,
        help="Caminho do arquivo .dump gerado por 'backup'. "
             "Padrao: o mais recente em --backups-dir."
    )
    restore_parser.add_argument(
        "--backups-dir",
        default="backups",
        help="Pasta onde procurar o dump mais recente, se --dump nao for informado."
    )
    restore_parser.add_argument(
        "--manifest",
        default=None,
        help="Caminho do manifesto (padrao: mesmo nome do dump, com .manifest.json)."
    )
    restore_parser.add_argument(
        "--yes",
        action="store_true",
        help="Nao pede confirmacao antes de restaurar (destroi o conteudo atual do TEST_DB_*)."
    )

    arguments = parser.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    env_file = _find_env_file(here, arguments.env_file)
    if env_file:
        load_dotenv(env_file)
        print(f".env: {env_file}")
    else:
        print(".env nao encontrado; usando as variaveis do ambiente.")

    if arguments.command == "backup":
        cmd_backup(arguments)
    elif arguments.command == "restore-test":
        cmd_restore_test(arguments)


if __name__ == "__main__":
    main()
