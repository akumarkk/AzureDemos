import os

import psycopg
from dotenv import load_dotenv

load_dotenv()


def get_connection() -> psycopg.Connection:
    return psycopg.connect(
        host=os.environ["PGHOST"],
        port=os.environ.get("PGPORT", "5432"),
        dbname=os.environ["PGDATABASE"],
        user=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        sslmode=os.environ.get("PGSSLMODE", "prefer"),
    )


def main() -> None:
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("SELECT version(), current_database(), current_user")
        version, db, user = cur.fetchone()
        print(f"Connected to '{db}' as '{user}'")
        print(version)


if __name__ == "__main__":
    main()
