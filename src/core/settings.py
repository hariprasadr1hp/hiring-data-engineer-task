import os
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore", env_file=".env")

    project_root: Path = Path(__file__).resolve().parents[2]
    data_dir: Path = project_root / "data"
    log_level: str = "DEBUG"

    postgres_host: str = "localhost"
    postgres_user: str = "postgres"
    postgres_password: str = "postgres"
    postgres_port: int = 5432
    postgres_db: str = "postgres"

    clickhouse_host: str = "localhost"
    clickhouse_port: int = 8123
    clickhouse_db: str = "default"
    clickhouse_user: str = "default"
    clickhouse_password: str = ""

    def apply_dbt(self):
        os.environ["POSTGRES_USER"] = "postgres"

    def apply_prefect(self):
        os.environ["PREFECT_PROFILE"] = "local"
        os.environ["PREFECT_LOGGING_LEVEL"] = "debug"


settings = Settings()
