{{ config(
    materialized='table',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_tradelicense_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_tradelicense_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (

    select *
    from {{ ref('d_langata_add_land_rates_count_to_join_cadastre') }}

),

licenses as (

    select uuid
    from {{ source('bronze_source', 'trade_license') }}

),

license_counts as (

    select uuid, count(*) as trade_count
    from licenses
    group by uuid

),

updated as (

    select
        c.*,
        coalesce(t.trade_count, 0) as trade_count
    from cadastre c
    left join license_counts t on c.uuid = t.uuid

)

select * from updated
