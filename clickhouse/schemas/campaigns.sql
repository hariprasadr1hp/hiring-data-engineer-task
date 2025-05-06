create table if not exists default.campaigns (
    id UInt32,
    name String,
    bid Float32,
    budget Float32,
    start_date Date,
    end_date Date,
    advertiser_id UInt32,
    updated_at Datetime,
    created_at Datetime
) engine = MergeTree()
order by id;
