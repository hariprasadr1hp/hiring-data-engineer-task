select
    event_date,
    campaign_id,
    campaign_name
    from {{ ref('int_campaign_performance') }}
where
    clicks > impressions
