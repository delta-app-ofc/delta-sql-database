"""Testes offline dos contratos de conexão, extração e carga do bi_etl."""

from datetime import datetime, timezone
import sys

import pytest

import bi_etl


class FakeCursor:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback):
        return False

    def execute(self, statement, params=None):
        sql = " ".join(statement.split())
        self.connection.statements.append((sql, params))
        if not sql.startswith("SELECT"):
            self.connection.pending = True

    def fetchone(self):
        return (self.connection.watermark,)

    def executemany(self, statement, rows):
        batch = list(rows)
        self.connection.batches.append((" ".join(statement.split()), batch))
        if batch:
            self.connection.pending = True
        if self.connection.fail_executemany:
            raise RuntimeError("falha sintética no batch")


class FakeConnection:
    def __init__(self, watermark=None, fail_executemany=False):
        self.watermark = watermark
        self.fail_executemany = fail_executemany
        self.statements = []
        self.batches = []
        self.commits = 0
        self.pending = False
        self.closed = False
        self.rolled_back_on_close = False

    def cursor(self):
        return FakeCursor(self)

    def commit(self):
        self.commits += 1
        self.pending = False

    def close(self):
        self.closed = True
        if self.pending:
            # psycopg2 desfaz transação pendente quando a conexão é fechada.
            self.rolled_back_on_close = True
            self.pending = False


class FakeMongoCursor:
    def __init__(self, documents):
        self.documents = list(documents)
        self.requested_batch_size = None

    def batch_size(self, size):
        self.requested_batch_size = size
        return self

    def __iter__(self):
        return iter(self.documents)


class FakeCollection:
    def __init__(self, documents=()):
        self.documents = list(documents)
        self.queries = []

    def find(self, query=None):
        self.queries.append(query if query is not None else {})
        return FakeMongoCursor(self.documents)


class FakeDatabase:
    def __init__(self, collections):
        self.collections = collections

    def __getitem__(self, name):
        return self.collections[name]


class FakeMongoClient:
    def __init__(self, databases):
        self.databases = databases
        self.requested_databases = []
        self.closed = False

    def __getitem__(self, name):
        self.requested_databases.append(name)
        return self.databases[name]

    def close(self):
        self.closed = True


def sample_consumption(**overrides):
    document = {
        "_id": "mongo-1",
        "device_id": "device-7",
        "user_id": 123,
        "window_started_at": datetime(2026, 10, 1, tzinfo=timezone.utc),
        "window_finished_at": datetime(2026, 10, 1, 1, tzinfo=timezone.utc),
        "consumption_liters": 12.5,
        "lpm_average": 0.21,
        "anomaly_detected": False,
    }
    document.update(overrides)
    return document


def test_find_env_file_prefers_explicit_path_then_optional_local_file(tmp_path):
    explicit = str(tmp_path / "chosen.env")
    local = tmp_path / ".env"

    assert bi_etl._find_env_file(str(tmp_path), explicit) == explicit
    assert bi_etl._find_env_file(str(tmp_path), None) is None

    local.write_text("DB_NAME=synthetic\n", encoding="utf-8")
    assert bi_etl._find_env_file(str(tmp_path), None) == str(local)


def test_postgres_params_use_required_values_and_safe_defaults(monkeypatch):
    monkeypatch.setenv("DB_HOST", "localhost")
    monkeypatch.setenv("DB_NAME", "delta_test")
    monkeypatch.setenv("DB_USER", "tester")
    monkeypatch.delenv("DB_PORT", raising=False)
    monkeypatch.delenv("DB_PASSWORD", raising=False)
    monkeypatch.delenv("DB_SSLMODE", raising=False)

    assert bi_etl._pg_connection_params() == {
        "host": "localhost",
        "port": "5432",
        "dbname": "delta_test",
        "user": "tester",
        "password": "",
        "sslmode": "prefer",
    }


@pytest.mark.parametrize("missing", ["DB_HOST", "DB_NAME", "DB_USER"])
def test_postgres_params_reject_each_missing_required_value(monkeypatch, missing):
    values = {"DB_HOST": "localhost", "DB_NAME": "delta_test", "DB_USER": "tester"}
    for name, value in values.items():
        if name == missing:
            monkeypatch.delenv(name, raising=False)
        else:
            monkeypatch.setenv(name, value)

    with pytest.raises(SystemExit, match="Faltam variaveis DB_HOST / DB_NAME / DB_USER"):
        bi_etl._pg_connection_params()


def test_mongo_client_requires_uri_and_sets_explicit_tls_option(monkeypatch):
    monkeypatch.setenv("MONGO_TEST_URI", "mongodb://test.invalid")
    created = []
    monkeypatch.setattr(
        bi_etl,
        "MongoClient",
        lambda uri, **kwargs: created.append((uri, kwargs)) or "fake-client",
    )

    assert bi_etl._mongo_client("MONGO_TEST_URI") == "fake-client"
    assert created == [("mongodb://test.invalid", {"tlsAllowInvalidCertificates": True})]

    monkeypatch.delenv("MONGO_TEST_URI")
    with pytest.raises(SystemExit, match="Falta a variavel MONGO_TEST_URI"):
        bi_etl._mongo_client("MONGO_TEST_URI")


def test_get_watermark_reads_maximum_timestamp_and_handles_empty_stage():
    watermark = datetime(2026, 10, 5, 12, tzinfo=timezone.utc)
    connection = FakeConnection(watermark=watermark)

    assert bi_etl._get_watermark(connection) == watermark
    assert connection.statements == [
        ("SELECT MAX(window_started_at) FROM stage.consumption_summary;", None)
    ]
    assert bi_etl._get_watermark(FakeConnection(watermark=None)) is None


@pytest.mark.parametrize(
    "watermark, expected_query",
    [
        (None, {}),
        (datetime(2026, 10, 5, tzinfo=timezone.utc),
         {"window_started_at": {"$gte": datetime(2026, 10, 5, tzinfo=timezone.utc)}}),
    ],
)
def test_extract_cursor_uses_inclusive_watermark_and_configured_batch(watermark, expected_query):
    collection = FakeCollection([sample_consumption()])
    client = FakeMongoClient({"telemetry": FakeDatabase({"consumption_summary": collection})})

    cursor = bi_etl._extract_cursor(client, "telemetry", watermark)

    assert collection.queries == [expected_query]
    assert cursor.requested_batch_size == bi_etl.BATCH_SIZE == 1000
    assert list(cursor) == [sample_consumption()]


def test_document_to_row_stringifies_ids_and_preserves_optional_nulls():
    row = bi_etl._document_to_row(
        sample_consumption(_id=987, user_id=None, lpm_average=None, anomaly_detected=None)
    )

    assert row == (
        "987",
        "device-7",
        None,
        datetime(2026, 10, 1, tzinfo=timezone.utc),
        datetime(2026, 10, 1, 1, tzinfo=timezone.utc),
        12.5,
        None,
        None,
    )


def test_document_to_row_rejects_missing_required_source_field():
    document = sample_consumption()
    del document["consumption_liters"]

    with pytest.raises(KeyError, match="consumption_liters"):
        bi_etl._document_to_row(document)


def test_stage_batch_skips_empty_batch_and_commits_nonempty_batch_once():
    connection = FakeConnection()
    assert bi_etl._load_stage_batch(connection, []) == 0
    assert connection.batches == []
    assert connection.commits == 0

    rows = [bi_etl._document_to_row(sample_consumption())]
    assert bi_etl._load_stage_batch(connection, rows) == 1
    assert connection.batches[0][1] == rows
    assert "ON CONFLICT (mongo_id) DO NOTHING" in connection.batches[0][0]
    assert connection.commits == 1


def test_stage_batch_failure_does_not_commit_and_propagates():
    connection = FakeConnection(fail_executemany=True)
    rows = [bi_etl._document_to_row(sample_consumption())]

    with pytest.raises(RuntimeError, match="falha sintética no batch"):
        bi_etl._load_stage_batch(connection, rows)

    assert connection.commits == 0
    assert connection.pending is True


def test_user_preferences_upsert_normalizes_missing_quiet_hours_and_options():
    collection = FakeCollection(
        [
            {
                "_id": "pref-1",
                "user_id": 10,
                "daily_liters_target": None,
                "notifications_enabled": False,
                "quiet_hours": {"start_hour": 22},
                "dark_mode_enabled": True,
            },
            {"_id": "pref-2", "user_id": 11, "quiet_hours": None, "dark_mode_enabled": False},
        ]
    )
    client = FakeMongoClient({"app": FakeDatabase({"user_preferences": collection})})
    connection = FakeConnection()

    assert bi_etl._load_user_preferences(connection, client, "app") == 2

    sql, rows = connection.batches[0]
    assert rows == [
        ("pref-1", 10, None, False, 22, None, True),
        ("pref-2", 11, None, None, None, None, False),
    ]
    assert "ON CONFLICT (mongo_id) DO UPDATE" in sql
    assert "quiet_start_hour" in sql and "dark_mode_enabled" in sql
    assert connection.commits == 1


def test_user_preferences_empty_collection_does_not_open_write_transaction():
    client = FakeMongoClient({"app": FakeDatabase({"user_preferences": FakeCollection()})})
    connection = FakeConnection()

    assert bi_etl._load_user_preferences(connection, client, "app") == 0
    assert connection.batches == []
    assert connection.commits == 0


def test_alert_history_upsert_preserves_optional_resolution_and_severity():
    collection = FakeCollection(
        [
            {"_id": "alert-1", "device_id": "d1", "user_id": 7, "alert_type": "leak",
             "triggered_at": "t1", "resolved_at": None},
            {"_id": "alert-2", "device_id": "d2", "user_id": 8, "alert_type": "flow",
             "triggered_at": "t2", "resolved_at": "t3", "severity": "high"},
        ]
    )
    client = FakeMongoClient({"app": FakeDatabase({"alerts_history": collection})})
    connection = FakeConnection()

    assert bi_etl._load_alerts_history(connection, client, "app") == 2

    sql, rows = connection.batches[0]
    assert rows == [
        ("alert-1", "d1", 7, "leak", "t1", None, None),
        ("alert-2", "d2", 8, "flow", "t2", "t3", "high"),
    ]
    assert "ON CONFLICT (mongo_id) DO UPDATE" in sql
    assert "resolved_at = EXCLUDED.resolved_at" in sql
    assert connection.commits == 1


def test_alert_history_empty_collection_does_not_commit():
    client = FakeMongoClient({"app": FakeDatabase({"alerts_history": FakeCollection()})})
    connection = FakeConnection()

    assert bi_etl._load_alerts_history(connection, client, "app") == 0
    assert connection.batches == []
    assert connection.commits == 0


def test_load_chain_runs_silver_then_gold_and_commits():
    connection = FakeConnection()

    bi_etl._run_load_chain(connection)

    assert [sql for sql, _ in connection.statements] == [
        "CALL silver.sp_load();",
        "CALL gold.sp_load();",
    ]
    assert connection.commits == 1


def test_load_chain_failure_does_not_commit_partial_chain():
    class FailingConnection(FakeConnection):
        def cursor(self):
            cursor = super().cursor()
            original_execute = cursor.execute

            def execute(statement, params=None):
                if "gold.sp_load" in statement:
                    raise RuntimeError("falha sintética no Gold")
                original_execute(statement, params)

            cursor.execute = execute
            return cursor

    connection = FailingConnection()

    with pytest.raises(RuntimeError, match="falha sintética no Gold"):
        bi_etl._run_load_chain(connection)

    assert connection.commits == 0


def main_clients(consumption_docs=(), preference_docs=(), alert_docs=()):
    telemetry = FakeMongoClient(
        {"db_delta_telemetry": FakeDatabase({"consumption_summary": FakeCollection(consumption_docs)})}
    )
    app = FakeMongoClient(
        {
            "db_delta_app": FakeDatabase(
                {
                    "user_preferences": FakeCollection(preference_docs),
                    "alerts_history": FakeCollection(alert_docs),
                }
            )
        }
    )
    return telemetry, app


def configure_main(monkeypatch, connection, clients):
    for name, value in {
        "DB_HOST": "postgres.invalid",
        "DB_NAME": "delta_test",
        "DB_USER": "etl_test",
        "MONGODB_TELEMETRY_URI": "mongodb://telemetry.invalid",
        "MONGODB_APP_URI": "mongodb://app.invalid",
    }.items():
        monkeypatch.setenv(name, value)
    monkeypatch.delenv("MONGO_DB_TELEMETRY", raising=False)
    monkeypatch.delenv("MONGO_DB_APP", raising=False)
    monkeypatch.setattr(bi_etl.psycopg2, "connect", lambda **kwargs: connection)
    opened = []

    def open_mongo(env_var):
        opened.append(env_var)
        return clients[len(opened) - 1]

    monkeypatch.setattr(bi_etl, "_mongo_client", open_mongo)
    monkeypatch.setattr(sys, "argv", ["bi_etl.py"])
    return opened


def test_main_loads_fixture_documents_and_closes_all_connections(monkeypatch, capsys):
    consumption = sample_consumption()
    preferences = {"_id": "pref-1", "user_id": 10, "dark_mode_enabled": True}
    alerts = {"_id": "alert-1", "device_id": "d1", "user_id": 10, "alert_type": "leak", "triggered_at": "t1"}
    connection = FakeConnection(watermark=None)
    clients = main_clients([consumption], [preferences], [alerts])
    opened = configure_main(monkeypatch, connection, clients)
    dotenv_files = []
    monkeypatch.setattr(bi_etl, "_find_env_file", lambda here, given: given)
    monkeypatch.setattr(bi_etl, "load_dotenv", lambda path: dotenv_files.append(path))
    monkeypatch.setattr(sys, "argv", ["bi_etl.py", "--env-file", "synthetic.env"])

    bi_etl.main()

    assert dotenv_files == ["synthetic.env"]
    assert opened == ["MONGODB_TELEMETRY_URI", "MONGODB_APP_URI"]
    assert clients[0].requested_databases == ["db_delta_telemetry"]
    assert clients[1].requested_databases == ["db_delta_app", "db_delta_app"]
    assert len(connection.batches) == 3
    assert connection.commits == 4
    assert connection.closed is True
    assert all(client.closed for client in clients)
    assert "buscando todo o historico" in capsys.readouterr().out


def test_main_closes_connections_and_leaves_failed_batch_uncommitted(monkeypatch):
    connection = FakeConnection(watermark=None, fail_executemany=True)
    clients = main_clients([sample_consumption()])
    configure_main(monkeypatch, connection, clients)
    monkeypatch.setattr(bi_etl, "_find_env_file", lambda here, given: None)
    monkeypatch.setattr(bi_etl, "load_dotenv", lambda path: pytest.fail(".env não deve ser carregado"))

    with pytest.raises(RuntimeError, match="falha sintética no batch"):
        bi_etl.main()

    assert connection.commits == 0
    assert connection.rolled_back_on_close is True
    assert connection.closed is True
    assert all(client.closed for client in clients)
