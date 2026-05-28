"""
Build db.sqlite from schema.sql and (by default) populate it from seed.sql.

Idempotent: drops the existing database if present and recreates from scratch.

Usage:
    python build.py             # schema + seed (default)
    python build.py --no-seed   # schema only

The schema is the source of truth; the seed is the source of truth for
example data. db.sqlite itself is a gitignored build artifact.
"""

import argparse
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).parent
DB_PATH = ROOT / "db.sqlite"
SCHEMA_PATH = ROOT / "schema.sql"
SEED_PATH = ROOT / "seed.sql"


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--no-seed",
        action="store_true",
        help="Skip seed.sql; create an empty schema only.",
    )
    args = parser.parse_args()

    if not SCHEMA_PATH.exists():
        print(f"error: {SCHEMA_PATH.name} not found", file=sys.stderr)
        return 1

    if DB_PATH.exists():
        DB_PATH.unlink()
        print(f"removed existing {DB_PATH.name}")

    conn = sqlite3.connect(DB_PATH)
    try:
        # SQLite ships with FK enforcement off — turn it on so REFERENCES
        # clauses in the schema actually do anything.
        conn.execute("PRAGMA foreign_keys = ON")

        conn.executescript(SCHEMA_PATH.read_text())
        print(f"loaded schema from {SCHEMA_PATH.name} ({_count_tables(conn)} tables)")

        if not args.no_seed:
            if not SEED_PATH.exists():
                print(
                    f"warning: {SEED_PATH.name} not found, skipping seed",
                    file=sys.stderr,
                )
            else:
                conn.executescript(SEED_PATH.read_text())
                print(f"loaded seed from {SEED_PATH.name}")
                _print_row_counts(conn)

        conn.commit()
    finally:
        conn.close()

    print(f"\nbuilt {DB_PATH.name}")
    return 0


def _count_tables(conn: sqlite3.Connection) -> int:
    cur = conn.execute(
        "SELECT COUNT(*) FROM sqlite_master "
        "WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    )
    return cur.fetchone()[0]


def _print_row_counts(conn: sqlite3.Connection) -> None:
    tables = [
        r[0]
        for r in conn.execute(
            "SELECT name FROM sqlite_master "
            "WHERE type='table' AND name NOT LIKE 'sqlite_%' "
            "ORDER BY name"
        )
    ]
    print("\nrow counts:")
    for table in tables:
        count = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  {table:34s} {count:>5d}")


if __name__ == "__main__":
    raise SystemExit(main())
