from pathlib import Path
from typing import Literal

import clickhouse_connect
import polars as pl

from src.errors import DataError

SQL_DIR = Path("./clickhouse/results")
DATA_DIR = Path("./data/")


def fetch_data_from_query(sql_path: Path) -> pl.DataFrame:
    if not sql_path.exists():
        raise DataError(f"Query file not found: {sql_path}")

    query = sql_path.read_text()
    client = clickhouse_connect.get_client(
        host="localhost", port=8123, username="default", password=""
    )

    result = client.query(query)
    return pl.DataFrame(result.result_rows, schema=result.column_names, orient="row")


def export_data(format: str = "stdout") -> None:
    if format not in ["stdout", "csv", "parquet"]:
        raise DataError("Invalid format. Use: stdout, csv, parquet")

    names = ["campaign_ctr", "daily_summary"]

    for name in names:
        sql_path = SQL_DIR / f"{name}.sql"
        df = fetch_data_from_query(sql_path)

        if format == "stdout":
            print(df)
        elif format == "csv":
            df.write_csv(DATA_DIR / f"{name}.csv")
        elif format == "parquet":
            df.write_parquet(DATA_DIR / f"{name}.parquet")
        else:
            raise DataError("Error: When using csv or parquet, pass a file name to save!")
