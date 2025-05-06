{{ config(
    materialized='incremental',
    unique_key=['campaign_id', 'event_date']
) }}

with impressions as (
    select
        campaign_id,
        toDate(created_at) as event_date,
        count(*) as impression_count
    from {{ ref('stg_impressions') }}
    {% if is_incremental() %}
    where
        toDate(created_at) >= today() - INTERVAL {{ var('backfill_days', 7) }} DAY
    {% endif %}
    group by campaign_id, toDate(created_at)
),

clicks as (
    select
        campaign_id,
        toDate(created_at) as event_date,
        count(*) as click_count
    from {{ ref('stg_clicks') }}
    {% if is_incremental() %}
    where
        toDate(created_at) >= today() - INTERVAL {{ var('backfill_days', 7) }} DAY
    {% endif %}
    group by campaign_id, toDate(created_at)
),

campaigns as (
    select
        campaign_id,
        campaign_name
    from {{ ref('stg_campaigns') }}
),

combined as (
    select
        coalesce(i.campaign_id, cl.campaign_id) as campaign_id,
        coalesce(i.event_date, cl.event_date) as event_date,
        coalesce(i.impression_count, 0) as impressions,
        coalesce(cl.click_count, 0) as clicks
    from impressions i
    full outer join clicks cl
      on i.campaign_id = cl.campaign_id
     and i.event_date = cl.event_date
)

select
    c.event_date,
    c.campaign_id,
    cmp.campaign_name,
    c.impressions,
    c.clicks,
    case
        when c.impressions > c.clicks then true
        else false
    end as are_impressions_gt_clicks
from combined c
left join campaigns cmp
  on c.campaign_id = cmp.campaign_id
