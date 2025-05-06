import httpx

from src.core.settings import settings


def load_parquet_to_clickhouse(path: str, table: str):
    print(f"[load] loading {path} into clickhouse table `{table}` via httpx...")
    url = f"http://{settings.clickhouse_host}:{settings.clickhouse_port}/"
    params = {"query": f"insert into {table} format parquet"}

    with open(path, "rb") as f:
        data = f.read()

    with httpx.Client() as client:
        response = client.post(url, params=params, content=data)

    if response.status_code != 200:
        raise Exception(f"[load] failed: {response.status_code} {response.text}")

    print(f"[load] inserted {path} into `{table}` successfully")
