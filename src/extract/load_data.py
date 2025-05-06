import sys

from src.extract.load_utils import load_parquet_to_clickhouse


def load_to_clickhouse():
    table = sys.argv[1]
    path = f"data/{table}.parquet"
    load_parquet_to_clickhouse(path, table)


if __name__ == "__main__":
    load_to_clickhouse()
