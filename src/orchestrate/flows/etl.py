import subprocess

from prefect import flow, task

from src.extract import advertisers, campaigns, clicks, impressions
from src.extract.load_utils import load_parquet_to_clickhouse


@task(name="extract")
def extract(table: str):
    print(f"Extracting {table}...")
    module = {
        "impressions": impressions,
        "clicks": clicks,
        "campaigns": campaigns,
        "advertisers": advertisers,
    }[table]
    module.run_extraction()


@task(name="load")
def load(table: str):
    path = f"data/{table}.parquet"
    print(f"Loading {table} from {path} into ClickHouse...")
    load_parquet_to_clickhouse(path, table)


@task(name="make")
def run_make(target: str):
    print(f"Running `make {target}`...")
    result = subprocess.run(["make", target], capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(result.stderr)
        raise Exception(f"`make {target}` failed with exit code {result.returncode}")


@flow(name="AdTech ETL Flow")
def run_etl_flow():
    tables = ["impressions", "clicks", "campaigns", "advertisers"]

    run_make("clickhouse-init")

    for table in tables:
        extract.submit(table).result()
        load.submit(table).result()

    run_make("dbt-deps")
    run_make("dbt-run")
    run_make("dbt-docs-generate")


if __name__ == "__main__":
    run_etl_flow()
