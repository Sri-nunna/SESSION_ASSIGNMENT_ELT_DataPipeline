"""Extract Titanic data from seaborn and load it unchanged into MySQL raw_titanic.

Python is used only for extraction/loading here. No cleaning or transformation is
performed. Re-running replaces the raw snapshot so it cannot append duplicate rows.
"""
import os
from datetime import datetime, timezone
from uuid import uuid4

import pandas as pd
import seaborn as sns
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL


load_dotenv()


def make_engine():
    required = ["MYSQL_HOST", "MYSQL_USER", "MYSQL_PASSWORD", "MYSQL_DATABASE"]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(
            "Missing MySQL environment variables: " + ", ".join(missing)
            + ". Set them before running the pipeline."
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


def extract_and_load():
    # Extract the original seaborn dataset. Do not fill nulls, rename columns,
    # cast values, or otherwise clean the dataframe.
    df = sns.load_dataset("titanic")

    # Required operational metadata; original dataset columns remain untouched.
    df["load_timestamp"] = datetime.now(timezone.utc).replace(tzinfo=None)
    df["batch_id"] = str(uuid4())

    engine = make_engine()
    try:
        # replace drops/recreates the snapshot table on each run, avoiding append
        # duplicates. Transformations happen only later in SQL.
        df.to_sql(
            name="raw_titanic",
            con=engine,
            if_exists="replace",
            index=False,
            chunksize=500,
            method="multi",
        )
        print(f"Loaded {len(df)} rows into raw_titanic.")
    finally:
        engine.dispose()


if __name__ == "__main__":
    extract_and_load()
