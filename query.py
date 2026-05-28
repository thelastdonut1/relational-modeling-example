import sqlite3
from pathlib import Path

ROOT = Path(__file__).parent
DB_PATH = ROOT / "db.sqlite"
QUERY_PATH = ROOT / "query.sql"


def main():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row

    sql = QUERY_PATH.read_text().strip()

    if not sql:
        print("query.sql is empty")
        return

    for r in conn.execute(sql):
        print(dict(r))

    conn.close()


if __name__ == "__main__":
    main()
