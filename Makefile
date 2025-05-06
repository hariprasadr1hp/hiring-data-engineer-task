ENV := dev
SRC := src

BLACK := uv run black
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

## DECLARE PHONY TARGETS #######################################################

.PHONY: \
  all help clean test lint format

################################################################################

