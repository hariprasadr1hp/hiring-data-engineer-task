{{ config(
    materialized='table'
) }}

with dates as (
    select
        event_date,
        sum(impressions) as impressions,
        sum(clicks) as clicks
    from {{ ref('int_campaign_performance') }}
    group by
        event_date
)

select
    event_date,
    impressions,
    clicks,
    {{ calculate_ctr('clicks', 'impressions') }} as ctr
from dates

