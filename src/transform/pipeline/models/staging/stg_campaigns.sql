select
    id as campaign_id,
    name as campaign_name,
    bid,
    budget,
    start_date,
    end_date,
    advertiser_id,
    updated_at,
    created_at
from {{ source('default', 'campaigns') }}
