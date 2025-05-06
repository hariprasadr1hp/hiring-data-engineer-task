from src.extract.extract_utils import extract_to_parquet


def run_extraction():
    query = """
    select
        id,
        name,
        updated_at,
        created_at
    from advertiser
    """
    extract_to_parquet(query, "advertisers.parquet")


if __name__ == "__main__":
    run_extraction()
