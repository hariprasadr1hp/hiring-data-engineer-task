import subprocess
from pathlib import Path
from typing import Literal

# import os
# import sys
# sys.path.insert(0, os.path.abspath("src"))
import typer

from src.core.settings import settings
from src.extract import advertisers, campaigns, clicks, impressions
from src.orchestrate.flows import etl
from src.serve.export_results import export_data

settings.apply_dbt()

app = typer.Typer()


@app.command(
    "extract-advertisers",
    help="Extract advertisers data from postgres and store as parquet at `./data/`",
)
def extract_advertisers():
    advertisers.run_extraction()


@app.command(
    "extract-campaigns",
    help="Extract campaign data from postgres and store as parquet at `./data/`",
)
def extract_campaigns():
    campaigns.run_extraction()


@app.command(
    "extract-clicks",
    help="Extract clicks data from postgres and store as parquet at `./data/`",
)
def extract_clicks():
    clicks.run_extraction()


@app.command(
    "extract-impressions",
    help="Extract impressions data from postgres and store as parquet at `./data/`",
)
def extract_impressions():
    impressions.run_extraction()


@app.command("etl-flow", help="Run full ETL (Prefect flow: extract → transform)")
def etl_flow():
    etl.run_etl_flow()


@app.command(
    "export-results", help="Export results from mart_campaign_kpis using ClickHouse + Polars"
)
def export_results(format: str = "stdout"):
    export_data(format=format)


if __name__ == "__main__":
    app()
