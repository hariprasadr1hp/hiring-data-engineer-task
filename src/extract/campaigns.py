from src.extract.extract_utils import extract_to_parquet


def run_extraction():
    query = """
    select
        id,
        name,
        bid,
        budget,
        start_date,
        end_date,
        advertiser_id,
        updated_at,
        created_at
    from campaign
    """
    extract_to_parquet(query, "campaigns.parquet")


if __name__ == "__main__":
    run_extraction()
