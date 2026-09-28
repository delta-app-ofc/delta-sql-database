import argparse
import os
import sys
from datetime import datetime

import psycopg2
from dotenv import load_dotenv
from pymongo import MongoClient


def _find_env_file(here: str, given: str | None) -> str | None:
    if given:
        return given

    candidate = os.path.join(here, ".env")
    if os.path.isfile(candidate):
        return candidate

    return None


def _pg_connection_params() -> dict:
    host = os.getenv("DB_HOST", "")
    name = os.getenv("DB_NAME", "")
    user = os.getenv("DB_USER", "")

    if not host or not name or not user:
        sys.exit(
            "Faltam variaveis DB_HOST / DB_NAME / DB_USER. "
            "Confira o .env."
        )

    return {
        "host": host,
        "port": os.getenv("DB_PORT", "5432"),
        "dbname": name,
        "user": user,
        "password": os.getenv("DB_PASSWORD", ""),
        "sslmode": os.getenv("DB_SSLMODE", "prefer"),
    }


def _mongo_client() -> MongoClient:
    uri = os.getenv("MONGODB_TELEMETRY_URI", "")

    if not uri:
        sys.exit("Falta a variavel MONGODB_TELEMETRY_URI. Confira o .env.")

    return MongoClient(uri)


BATCH_SIZE = 1000


def _get_watermark(connection) -> datetime | None:
    with connection.cursor() as cursor:
        cursor.execute("SELECT MAX(window_started_at) FROM stage.consumption_summary;")
        (watermark,) = cursor.fetchone()

    return watermark


def _extract_cursor(mongo_client: MongoClient, mongo_db_name: str, watermark: datetime | None):
    collection = mongo_client[mongo_db_name]["consumption_summary"]
    # >= (nao >) porque pode haver mais de um documento com o mesmo window_started_at do
    # watermark atual - o ON CONFLICT (mongo_id) DO NOTHING em _load_stage_batch descarta os
    # que ja foram carregados, sem perder os que ainda nao foram.
    query = {"window_started_at": {"$gte": watermark}} if watermark is not None else {}
    return collection.find(query).batch_size(BATCH_SIZE)


def _document_to_row(doc: dict) -> tuple:
    return (
        str(doc["_id"]),
        doc["device_id"],
        str(doc.get("user_id")) if doc.get("user_id") is not None else None,
        doc["window_started_at"],
        doc["window_finished_at"],
        doc["consumption_liters"],
        doc.get("lpm_average"),
        doc.get("anomaly_detected"),
    )


def _load_stage_batch(connection, rows: list) -> int:
    if not rows:
        return 0

    with connection.cursor() as cursor:
        cursor.executemany(
            """
            INSERT INTO stage.consumption_summary
                (mongo_id, device_id, user_id, window_started_at, window_finished_at, consumption_liters, lpm_average, anomaly_detected)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (mongo_id) DO NOTHING;
            """,
            rows,
        )

    connection.commit()
    return len(rows)


def _run_load_chain(connection) -> None:
    with connection.cursor() as cursor:
        cursor.execute("CALL silver.sp_load();")
        cursor.execute("CALL gold.sp_load();")

    connection.commit()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", default=None)
    arguments = parser.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    env_file = _find_env_file(here, arguments.env_file)

    if env_file:
        load_dotenv(env_file)
        print(f".env: {env_file}")
    else:
        print(".env nao encontrado; usando as variaveis do ambiente.")

    mongo_db_name = os.getenv("MONGO_DB_TELEMETRY", "db_delta_telemetry")

    pg_connection = psycopg2.connect(**_pg_connection_params())
    mongo_client = _mongo_client()

    try:
        watermark = _get_watermark(pg_connection)
        if watermark is None:
            print("stage.consumption_summary vazio - buscando todo o historico do Mongo.")
        else:
            print(f"Buscando documentos com window_started_at >= {watermark.isoformat()}")

        cursor_docs = _extract_cursor(mongo_client, mongo_db_name, watermark)

        total_found = 0
        total_inserted = 0
        batch: list = []

        for doc in cursor_docs:
            total_found += 1
            batch.append(_document_to_row(doc))

            if len(batch) >= BATCH_SIZE:
                total_inserted += _load_stage_batch(pg_connection, batch)
                batch = []

        total_inserted += _load_stage_batch(pg_connection, batch)

        print(f"Documentos encontrados no Mongo: {total_found}")
        print(f"Linhas inseridas em stage.consumption_summary: {total_inserted}")

        _run_load_chain(pg_connection)
        print("silver.sp_load() e gold.sp_load() executados com sucesso.")

    finally:
        mongo_client.close()
        pg_connection.close()


if __name__ == "__main__":
    main()
