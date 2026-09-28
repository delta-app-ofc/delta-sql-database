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


def _get_watermark(connection) -> datetime | None:
    with connection.cursor() as cursor:
        cursor.execute("SELECT MAX(window_started_at) FROM stage.consumption_summary;")
        (watermark,) = cursor.fetchone()

    return watermark


def _extract_documents(mongo_client: MongoClient, mongo_db_name: str, watermark: datetime | None):
    collection = mongo_client[mongo_db_name]["consumption_summary"]
    query = {"window_started_at": {"$gt": watermark}} if watermark is not None else {}
    return list(collection.find(query))


def _load_stage(connection, documents: list) -> int:
    if not documents:
        return 0

    rows = [
        (
            str(doc["_id"]),
            doc["device_id"],
            str(doc.get("user_id")) if doc.get("user_id") is not None else None,
            doc["window_started_at"],
            doc["window_finished_at"],
            doc["consumption_liters"],
            doc.get("lpm_average"),
            doc.get("anomaly_detected"),
        )
        for doc in documents
    ]

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
            print(f"Buscando documentos com window_started_at > {watermark.isoformat()}")

        documents = _extract_documents(mongo_client, mongo_db_name, watermark)
        print(f"Documentos encontrados no Mongo: {len(documents)}")

        inserted = _load_stage(pg_connection, documents)
        print(f"Linhas inseridas em stage.consumption_summary: {inserted}")

        _run_load_chain(pg_connection)
        print("silver.sp_load() e gold.sp_load() executados com sucesso.")

    finally:
        mongo_client.close()
        pg_connection.close()


if __name__ == "__main__":
    main()
