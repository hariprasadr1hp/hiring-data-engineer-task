# tests/test_clickhouse_tables.py

import httpx

from src.core.settings import settings


def query_clickhouse(sql: str):
    url = f"http://{settings.clickhouse_host}:{settings.clickhouse_port}/"
    with httpx.Client() as client:
        response = client.post(url, params={"query": sql})
        assert response.status_code == 200, f"ClickHouse error: {response.text}"
        return response.text.strip()


def test_table_exists_and_not_empty():
    tables = ["impressions", "clicks", "campaigns", "advertisers"]
    for table in tables:
        result = query_clickhouse(f"select count() from {table}")
        assert int(result) > 0, f"Table {table} is empty or missing"
