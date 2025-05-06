import os

import polars as pl
import psycopg2

from src.core.settings import settings

DATA_DIR = "data"


def extract_to_parquet(query: str, output_file: str):
    os.makedirs(DATA_DIR, exist_ok=True)

    conn = psycopg2.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        dbname=settings.postgres_db,
        user=settings.postgres_user,
        password=settings.postgres_password,
    )

    df = pl.read_database(query, connection=conn)
    conn.close()

    full_path = os.path.join(DATA_DIR, output_file)
    df.write_parquet(full_path)
    print(f"[extract] wrote {df.shape[0]} rows to {full_path}")
