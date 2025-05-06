import typer

from src.core.settings import settings
from src.extract import advertisers, campaigns, clicks, impressions

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


if __name__ == "__main__":
    app()
