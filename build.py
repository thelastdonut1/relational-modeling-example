"""
Build db.sqlite from schema.sql.

Idempotent: drops the existing database if present and recreates from scratch.
The schema is the source of truth - db.sqlite is a build artifact and is
gitignored.
"""

import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).parent
DB_PATH = ROOT / "db.sqlite"
SCHEMA_PATH = ROOT / "schema.sql"


def main() -> int:
    if not SCHEMA_PATH.exists():
        print(f"Error: {SCHEMA_PATH.name} not found", file=sys.stderr)
        return 1

    if DB_PATH.exists():
        DB_PATH.unlink()
        print(f"Removed exisiting {DB_PATH.name}")

    schema = SCHEMA_PATH.read_text()
    conn = sqlite3.connect(DB_PATH)

    try:
        # SQLite ships with FK enforcement off by default - turn it on
        # so REFERENCES clauses in the schema actually do something
        conn.execute("PRAGMA foreign_keys = ON")
        conn.executescript(schema)
        conn.commit()
    finally:
        conn.close()

    print(f"built {DB_PATH.name} from {SCHEMA_PATH.name}")
    print(f"  tables: {_count_tables()}")
    return 0


def _count_tables() -> int:
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.execute(
            "SELECT COUNT(*) FROM sqlite_master "
            "WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )
        return cur.fetchone()[0]
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
