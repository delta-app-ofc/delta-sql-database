"""Vincula uma conta existente aos dados Swift no Docker local, sem recriar o banco."""

import argparse
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--email", required=True, help="E-mail da conta criada pelo cadastro")
    args = parser.parse_args()
    email = args.email.strip()
    if not email or "@" not in email or any(c in email for c in "\r\n\0"):
        parser.error("Informe um e-mail valido.")
    script = Path(__file__).with_name("script-dev-vincular-usuario.sql")
    try:
        result = subprocess.run(
            ["docker", "exec", "-i", "delta-pg-test", "psql", "-U", "postgres",
             "-d", "deltadb", "-v", "ON_ERROR_STOP=1", "-v", f"email={email}"],
            input=script.read_bytes(), check=False,
        )
    except FileNotFoundError:
        print("Docker nao encontrado. Abra o Docker Desktop e confira a instalacao.", file=sys.stderr)
        return 1
    if result.returncode:
        print("Vinculo nao concluido. Confira a conta e o container delta-pg-test.", file=sys.stderr)
    else:
        print("Vinculo concluido. Saia da conta e entre novamente no site.")
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
