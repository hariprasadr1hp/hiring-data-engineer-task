create table if not exists impressions (
    id UInt32,
    campaign_id UInt32,
    created_at Datetime,
) engine = MergeTree()
partition by toYYYYMM(created_at)
order by (created_at, campaign_id);
