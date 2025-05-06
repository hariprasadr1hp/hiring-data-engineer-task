create table if not exists default.advertisers (
    id UInt32,
    name String,
    updated_at Datetime,
    created_at Datetime
) engine = MergeTree()
order by id;

