import os

import httpx
import polars as pl
import pytest

from src.core.settings import settings

DATA_DIR = "data"


def get_parquet(path):
    full_path = os.path.join(DATA_DIR, path)
    assert os.path.exists(full_path), f"Missing file: {full_path}"
    return pl.read_parquet(full_path)


@pytest.mark.parametrize(
    "filename,expected_cols",
    [
        ("impressions.parquet", ["id", "campaign_id", "created_at"]),
        ("clicks.parquet", ["id", "campaign_id", "created_at"]),
        (
            "campaigns.parquet",
            [
                "id",
                "name",
                "bid",
                "budget",
                "start_date",
                "end_date",
                "advertiser_id",
                "updated_at",
                "created_at",
            ],
        ),
        ("advertisers.parquet", ["id", "name", "updated_at", "created_at"]),
    ],
)
def test_parquet_schema(filename, expected_cols):
    df = get_parquet(filename)
    assert set(expected_cols).issubset(df.columns), f"{filename} missing expected columns"


@pytest.mark.parametrize(
    "filename",
    [
        "impressions.parquet",
        "clicks.parquet",
        "campaigns.parquet",
        "advertisers.parquet",
    ],
)
def test_parquet_not_empty(filename):
    df = get_parquet(filename)
    assert df.shape[0] > 0, f"{filename} should not be empty"


def test_clickhouse_response():
    url = f"http://{settings.clickhouse_host}:{settings.clickhouse_port}/"
    params = {"query": "select 1"}

    with httpx.Client() as client:
        response = client.get(url, params=params)

    assert response.status_code == 200, "ClickHouse did not respond successfully"
    assert response.text.strip() == "1", "Unexpected ClickHouse result"
