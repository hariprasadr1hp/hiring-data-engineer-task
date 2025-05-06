ENV := dev
SRC := src

BLACK := uv run black
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

clean:
	@echo "Cleaning up..."
	find . -name '__pycache__' -exec rm -rf {} +
	find . -name '*.pyc' -exec rm -rf {} +
	rm -f junit.xml .coverage
	rm -rf .mypy_cache/ .pytest_cache/ .ruff_cache/
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
  etl-flow extract \
  clickhouse-init clickhouse-clean clickhouse-reset clickhouse-shell clickhouse-stats \
  all help clean test lint format

################################################################################

