select
    id as advertiser_id,
    name as advertiser_name,
    updated_at,
    created_at
from {{ source('default', 'advertisers') }}
