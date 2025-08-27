{{ config(
    materialized='incremental',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_landrates_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_landrates_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (

    select *
    from {{ ref('d_langata_cp_power_water_bld_permits_add_name') }}

),

land_rates as (

    select property_reference as uuid
    from {{ source('bronze_source', 'bd_land_rate_data') }}

),

rate_counts as (

    select uuid, count(*) as rates_count
    from land_rates
    group by uuid

),

updated as (

    select
        c.*,
        coalesce(r.rates_count, 0) as rates_count
    from cadastre c
    left join rate_counts r on c.uuid = r.uuid

)

select * from updated
