import typer

from src.core.settings import settings
from src.extract import advertisers, campaigns, clicks, impressions
from src.orchestrate.flows import etl

app = typer.Typer()


@app.command("extract-advertisers")
def extract_advertisers():
    advertisers.run_extraction()


@app.command("extract-campaigns")
def extract_campaigns():
    campaigns.run_extraction()


@app.command("extract-clicks")
def extract_clicks():
    clicks.run_extraction()


@app.command("extract-impressions")
def extract_impressions():
    impressions.run_extraction()


@app.command("etl-flow")
def etl_flow():
    etl.run_etl_flow()


@app.command("prefect-serve")
def serve_prefect():
    settings.apply_prefect()
    cmd = ["uv", "run", "--", "prefect", "server", "start"]
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    app()
