from src.extract.extract_utils import extract_to_parquet


def run_extraction():
    query = """
    select
        id,
        campaign_id,
        created_at
    from clicks
    """
    extract_to_parquet(query, "clicks.parquet")


if __name__ == "__main__":
    run_extraction()
