{{ config(
    materialized='table'
) }}

with campaigns as (
    select
        campaign_id,
        campaign_name,
        sum(impressions) as impressions,
        sum(clicks) as clicks
    from {{ ref('int_campaign_performance') }}
    group by
        campaign_id,
        campaign_name
)

select
    campaign_id,
    campaign_name,
    impressions,
    clicks,
    {{ calculate_ctr('clicks', 'impressions') }} as ctr
from campaigns

