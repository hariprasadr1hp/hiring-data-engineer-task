ENV := dev
SRC := src
DBT_PROJECT_DIR := $(SRC)/transform/pipeline
DBT_PROFILES_DIR := $(DBT_PROJECT_DIR)
DBT_LOG_DIR := $(DBT_PROJECT_DIR)/logs
DBT_TARGET_DIR := $(DBT_PROJECT_DIR)/target

BLACK := uv run black
DBT := uv run dbt
PREFECT := uv run prefect
PYTEST := uv run pytest
PYTHON := uv run python
RUFF := uv run ruff
CLI = uv run python cli.py

## Print this menu
all: help

## Print this menu
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk '\
		/^## / { sub(/^## /, "", $$0); help = $$0; next } \
		/^[a-zA-Z0-9_-]+:/ { \
			split($$1, parts, ":"); \
			printf "  %-20s %s\n", parts[1], (help ? help : "not available"); \
			help = "" \
		} \
	' $(MAKEFILE_LIST)

## Remove DBT, and Python build artifacts
clean:
	@echo "Cleaning up..."
	find . -name '__pycache__' -exec rm -rf {} +
	find . -name '*.pyc' -exec rm -rf {} +
	rm -f junit.xml .coverage
	rm -rf .mypy_cache/ .pytest_cache/ .ruff_cache/
	rm -rf $(DBT_LOG_DIR) $(DBT_TARGET_DIR)
	@echo "Clean up complete."

## PYTHON TOOLING ##############################################################

## Run tests
test:
	$(PYTEST)

## Run linting (using `ruff`)
lint:
	$(RUFF) check $(SRC)

## Run formatting (using `black`)
format:
	$(BLACK) $(SRC)

## SOURCE ######################################################################

## Sets up the project
setup:
	docker-compose up -d
	db-seed

## Reset database data
reset:
	uv run python main.py reset

## Seed batch data
postgres-seed:
	uv run python main.py batch --advertisers 5 --campaigns 3 --impressions 1000 --ctr 0.08

## Show Stats
postgres-stats:
	uv run python main.py stats

## EXTRACT #####################################################################

## Run the extract pipeline (Polars: PostgreSQL → ClickHouse)
extract:
	$(CLI) extract-advertisers
	$(CLI) extract-campaigns
	$(CLI) extract-clicks
	$(CLI) extract-impressions

## Run full ETL (Prefect flow: extract → transform)
etl-flow:
	$(CLI) etl-flow

## Prefect Server
prefect-serve:
	$(PYTHON) cli.py prefect-serve

## DBT #########################################################################

## Remove dbt artifacts
dbt-clean:
	cd $(DBT_PROJECT_DIR) && $(DBT) clean

## Debug dbt profiles/config
dbt-debug:
	$(DBT) debug \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## Install dbt dependencies
dbt-deps:
	$(DBT) deps \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## Generate dbt docs
dbt-docs-generate:
	$(DBT) docs generate \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## Serve dbt docs
dbt-docs-serve:
	$(DBT) docs serve \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## Run dbt models
dbt-run:
	$(DBT) run \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## Refresh dbt models
dbt-refresh:
	$(DBT) run \
		--full-refresh \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)


## Load seed data
dbt-seed:
	$(DBT) seed \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## Test dbt models
dbt-test:
	$(DBT) test \
		--project-dir $(DBT_PROJECT_DIR) \
		--profiles-dir $(DBT_PROFILES_DIR) \
		--log-path $(DBT_LOG_DIR)

## CLICKHOUSE ##################################################################

## Initialize clickhouse database
clickhouse-init:
	docker exec -i ch_analytics clickhouse-client < clickhouse/schemas/advertisers.sql
	docker exec -i ch_analytics clickhouse-client < clickhouse/schemas/campaigns.sql
	docker exec -i ch_analytics clickhouse-client < clickhouse/schemas/clicks.sql
	docker exec -i ch_analytics clickhouse-client < clickhouse/schemas/impressions.sql

## Drop all ClickHouse tables defined in schemas
clickhouse-clean:
	for file in clickhouse/schemas/*.sql; do \
		table=$$(basename $$file .sql); \
		echo "Dropping table: $$table"; \
		docker exec -i ch_analytics clickhouse-client --query="drop table if exists $$table"; \
	done

## Truncate all ClickHouse tables (preserve schema)
clickhouse-reset:
	for file in clickhouse/schemas/*.sql; do \
		table=$$(basename $$file .sql); \
		echo "Truncating table: $$table"; \
		docker exec -i ch_analytics clickhouse-client --query="truncate table if exists $$table"; \
	done

## Show Stats
clickhouse-stats:
	docker exec -i ch_analytics clickhouse-client < clickhouse/stats.sql

## Interactive-Shell Mode
clickhouse-shell:
	docker exec -ti ch_analytics clickhouse-client

## DECLARE PHONY TARGETS #######################################################

.PHONY: \
  dbt-clean dbt-debug dbt-deps dbt-docs-generate dbt-docs-serve \
  dbt-run dbt-seed dbt-test \
  etl-flow extract \
  clickhouse-init clickhouse-clean clickhouse-reset clickhouse-shell clickhouse-stats \
  all help clean test lint format

################################################################################

