# Data Engineering Task: AdTech Data Pipeline

Developing a data pipeline for an advertising platform.

Refer to the assigned task [here](./task.md).

## How to Run?

### Commands

```bash
# Install dependencies
uv sync

# Start all services, as a given for the task (postgres and clickhouse)
make setup

# Start Prefect Server (prefect-service as a container)
make prefect-serve

# Seeding data into postgres tables (from `seed.py`, given in the task)
make postgres-seed

# Run the complete ETL pipeline
make etl-flow

# To print the generated tables
make show-results

# To export data as CSV
python cli.py export-results --format=csv

# To export data as parquet
python cli.py export-results --format=parquet
```

### Additional Notes

To run tasks individually

```bash
# To view all the available commands
make help

# To run the extract phase alone
make extract

# To create clickhouse tables (only initialize)
make clickhouse-init

# DBT related
# updates dependencies
make dbt-deps

# runs tranformation (batch-loading)
make dbt-run

# runs full transformation (init-loading)
make dbt-run-full-refresh
```

list of all `make` targets (running `make help`)

```
Available targets:
  all                  Print this menu
  help                 Print this menu
  clean                Remove DBT, and Python build artifacts
  test                 Run tests
  lint                 Run linting (using `ruff`)
  format               Run formatting (using `black`)
  setup                Sets up the project
  reset                Reset database data
  postgres-seed        Seed batch data
  postgres-stats       Show Stats
  extract              Run the extract pipeline (Polars: PostgreSQL → ClickHouse)
  etl-flow             Run full ETL (Prefect flow: extract → transform)
  prefect-serve        Prefect Server
  show-results         Export results from mart_campaign_kpis using ClickHouse + Polars
  dbt-clean            Remove dbt artifacts
  dbt-debug            Debug dbt profiles/config
  dbt-deps             Install dbt dependencies
  dbt-docs-generate    Generate dbt docs
  dbt-docs-serve       Serve dbt docs
  dbt-run              Run dbt models
  dbt-run-full-refresh Refresh dbt models
  dbt-seed             Load seed data
  dbt-test             Test dbt models
  clickhouse-init      Initialize clickhouse database
  clickhouse-clean     Drop all ClickHouse tables defined in schemas
  clickhouse-reset     Truncate all ClickHouse tables (preserve schema)
  clickhouse-stats     Show Stats
  clickhouse-shell     Interactive-Shell Mode
```

## Code Structure

The entire data-stack can be found under `./src` directory

```
src/
├── compose         # docker services
├── core            # project settings
├── extract         # extracting data from postgres tables
├── orchestrate     # data pipeline DAGs (prefect)
├── serve           # exporting the results of interest
├── tests           # relevant tests for each phase
└── transform       # rendering raw tables into processed tables (using dbt)
```

## Workflow

### Setting up Project Environment

- The required project environmental variables are loaded from `.env`
- If not available, then the sane [defaults are set and managed](./src/core/settings.py) using `pydantic_settings`
- A [Makefile](./Makefile) with targets representing different stages on the ETL process
- based on the [CLI](./cli.py) endpoints, managed by `typer`
-

### Extraction Phase

- The postgres tables are populated using the functionality`make postgres-seed` command
- Extract data from sources (impressions, clicks, campaigns, advertisers)
- And store them as `*.parquet` files under `./data/` directory
- for clickhouse consumption (not implemented yet)
- In order to load the extracted tables from Postgres to Clickhouse,
- initialize clickhouse tables with relevant schema using `make clickhouse-init`
- Run `make test`, to run all tests related to the extraction process
- The parquet files are then [loaded as clickhouse tables](./src/extract/load_data.py) with corresponding names

### Transformation using `DBT`

- Register clickhouse db connection info at [`profiles.yml`](./src/transform/pipeline/profiles.yml)
- Splitting the transformation phase into 3 stages: `staging`, `intermmedite`, and `marts`
- Load the raw tables into `staging/`
- Intermediary logic in `intermediate/`
- i.e) Merging clicks and impressions together, grouped by campaign and date information
- And the final processed tables at `marts/`
- By running `make dbt-docs-serve`, the DBT generated docs can be viewed [here](http://localhost:8080)

### KPI Queries

The following tables are created using the queries at `marts/`

- `fct_daily_summary`, (date, clicks, impressions, CTR)
- `fct_campaign_ctr`, CTR by campaign (campaign name/id, clicks, impressions, CTR)

For dimensions, when the clicks are greater than impressions, CTR is defaulted to 1
The logic is [macro-ed](./src/transform/pipeline/macros/calc_ctr.sql) for extensibility
The [tests](./src/transform/pipeline/tests/) can be run using `make dbt-test`

### Add ETL Orchestration

- Using `prefect` as the orchestration tool for managing DAGs
- Spinning up the prefect service, using `make prefect-serve`
- [Adding `tasks`](./src/orchestrate/flows/etl.py) related to the extract/load phase

```python
@flow(name="AdTech ETL Flow")
def run_etl_flow():

    # 1.Initializing clickhouse tables
    run_make("clickhouse-init")

    # 2.Extract tables from postgres and loading to clickhouse
    tables = ["impressions", "clicks", "campaigns", "advertisers"]
    for table in tables:
        extract.submit(table).result()
        load.submit(table).result()

    # 3. Running transformation process
    run_make("dbt-deps")
    run_make("dbt-run")
    run_make("dbt-docs-generate")
```

- All flow related information can be viewed at the [dashboard](http://localhost:4200/dashboard)

### Viewing results

- The Generated results can viewed using `make show-results`
- Or can be found under `./data/directory` under the names `daily_summary` and `campaign_ctr`, after running
- `python cli.py export-results --format=csv` and `python cli.py export-results --format=parquet`
- for generating CSV and parquet files respectively
