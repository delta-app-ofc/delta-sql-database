import pytest

import migrate_db


class FakeCursor:
    def __init__(self, connection):
        self.connection = connection
        self._rows = []

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def execute(self, sql, params=None):
        self.connection.executed.append(sql)
        if "information_schema.schemata" in sql:
            self._rows = [(name,) for name in self.connection.schemas]
        elif "information_schema.views" in sql:
            self._rows = [(17,)]

    def fetchall(self):
        return self._rows

    def fetchone(self):
        return self._rows[0]


class FakeConnection:
    def __init__(self, schemas=("stage", "silver", "gold", "dw")):
        self.schemas = schemas
        self.executed = []
        self.notices = []
        self.commits = 0
        self.rollbacks = 0
        self.closed = False

    def cursor(self):
        return FakeCursor(self)

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1

    def close(self):
        self.closed = True


@pytest.fixture
def env(monkeypatch, tmp_path):
    for name, value in {"DB_HOST": "db.invalid", "DB_NAME": "delta", "DB_USER": "etl"}.items():
        monkeypatch.setenv(name, value)
    monkeypatch.setattr(migrate_db, "_find_env_file", lambda here, given: None)
    (tmp_path / migrate_db.MIGRATION).write_text("SELECT 1;", encoding="utf-8")
    (tmp_path / migrate_db.SEED).write_text("SELECT 2;", encoding="utf-8")
    return tmp_path


def test_plan_adds_the_seed_only_when_requested():
    assert migrate_db.plan(False) == [migrate_db.MIGRATION, "silver.sp_load() + gold.sp_load()"]
    assert migrate_db.plan(True)[-1] == migrate_db.SEED


def test_dry_run_never_connects(env, monkeypatch, capsys):
    monkeypatch.setattr(migrate_db.psycopg2, "connect", lambda **kwargs: pytest.fail("nao deve conectar"))

    migrate_db.main(["--dry-run", "--scripts-dir", str(env)])

    assert "Dry-run" in capsys.readouterr().out


def test_runs_migration_then_load_chain_and_commits(env, monkeypatch):
    connection = FakeConnection()
    monkeypatch.setattr(migrate_db.psycopg2, "connect", lambda **kwargs: connection)

    migrate_db.main(["--yes", "--scripts-dir", str(env)])

    statements = [sql for sql in connection.executed if sql.startswith(("SELECT 1", "CALL"))]
    assert statements[0] == "SELECT 1;"
    assert "CALL silver.sp_load();" in statements[1] and "CALL gold.sp_load();" in statements[1]
    assert "SELECT 2;" not in connection.executed
    assert connection.commits == 2 and connection.closed is True


def test_seed_runs_last_when_requested(env, monkeypatch):
    connection = FakeConnection()
    monkeypatch.setattr(migrate_db.psycopg2, "connect", lambda **kwargs: connection)

    migrate_db.main(["--yes", "--seed-swift", "--scripts-dir", str(env)])

    assert [sql for sql in connection.executed if sql.startswith("SELECT ")][:2] == ["SELECT 1;", "SELECT 2;"] or "SELECT 2;" in connection.executed
    assert connection.executed.index("SELECT 2;") > connection.executed.index("SELECT 1;")


def test_refuses_a_database_without_the_datamart(env, monkeypatch):
    connection = FakeConnection(schemas=("public",))
    monkeypatch.setattr(migrate_db.psycopg2, "connect", lambda **kwargs: connection)

    with pytest.raises(SystemExit, match="setup_db.py"):
        migrate_db.main(["--yes", "--scripts-dir", str(env)])

    assert "SELECT 1;" not in connection.executed
    assert connection.closed is True


def test_missing_script_stops_before_connecting(env, monkeypatch):
    (env / migrate_db.MIGRATION).unlink()
    monkeypatch.setattr(migrate_db.psycopg2, "connect", lambda **kwargs: pytest.fail("nao deve conectar"))

    with pytest.raises(SystemExit, match="nao encontrado"):
        migrate_db.main(["--yes", "--scripts-dir", str(env)])
