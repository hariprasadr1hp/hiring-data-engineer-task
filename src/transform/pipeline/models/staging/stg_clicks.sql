select
    id as click_id,
    campaign_id,
    toDate(created_at) as event_date,
    created_at
from {{ source('default', 'clicks') }}
