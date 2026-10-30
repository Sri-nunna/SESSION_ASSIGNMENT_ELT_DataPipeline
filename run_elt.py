"""Run the full Titanic ELT pipeline in order."""
import os
import re
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

from extract_load import extract_and_load

load_dotenv()

ROOT = Path(__file__).resolve().parent
SQL_FILES = [
    ROOT / "sql" / "01_staging.sql",
    ROOT / "sql" / "02_transform.sql",
    ROOT / "sql" / "03_analytics.sql",
    ROOT / "sql" / "04_data_quality.sql",
]


def make_engine():
    required = ["MYSQL_HOST", "MYSQL_USER", "MYSQL_PASSWORD", "MYSQL_DATABASE"]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(
            "Missing MySQL environment variables: " + ", ".join(missing)
        )
    url = URL.create(
        "mysql+pymysql",
        username=os.environ["MYSQL_USER"],
        password=os.environ["MYSQL_PASSWORD"],
        host=os.environ["MYSQL_HOST"],
        port=int(os.getenv("MYSQL_PORT", "3306")),
        database=os.environ["MYSQL_DATABASE"],
        query={"charset": "utf8mb4"},
    )
    return create_engine(url, pool_pre_ping=True)


def run_sql_file(engine, path):
    # These project SQL files contain ordinary statements separated by semicolons,
    # and do not contain stored procedures or semicolons inside string literals.
    sql_text = path.read_text(encoding="utf-8")
    sql_text = re.sub(r"(?m)^\s*--.*$", "", sql_text)
    statements = [part.strip() for part in sql_text.split(";") if part.strip()]
    with engine.begin() as connection:
        for statement in statements:
            connection.exec_driver_sql(statement)
    print(f"Executed {path.relative_to(ROOT)}")


def print_quality_results(engine):
    with engine.connect() as connection:
        rows = connection.execute(
            text("SELECT check_name, status FROM dq_results ORDER BY check_name")
        ).fetchall()

    for check_name, status in rows:
        print(f"{status}: {check_name}")

    if not rows or any(status != "PASS" for _, status in rows):
        raise SystemExit("One or more data quality checks failed.")


def main():
    extract_and_load()
    engine = make_engine()
    try:
        for sql_file in SQL_FILES:
            run_sql_file(engine, sql_file)
        print_quality_results(engine)
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
