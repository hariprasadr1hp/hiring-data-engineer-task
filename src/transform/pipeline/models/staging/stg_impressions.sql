select
    id as impression_id,
    toDate(created_at) as event_date,
    campaign_id,
    created_at
from {{ source('default', 'impressions') }}
