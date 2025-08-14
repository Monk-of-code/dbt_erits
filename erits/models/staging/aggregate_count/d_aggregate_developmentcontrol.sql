{{config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_aggregate_development ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_aggregate_development_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
)}}

with permits as (

    select *
    from {{ ref('d_langata_building_permits') }}

),

cadastre as (

    select uuid, geom
    from {{ ref('d_langata_cp_cadastral_parcel_uuid') }}

),

intersections as (

    select
        c.uuid,
        p.geom as permits_geom
    from permits p
    join cadastre c
    on ST_Intersects(p.geom, c.geom)

),

aggregated as (

    select
        c.uuid,
        c.geom,
        count(i.permits_geom) as permit_count
    from cadastre c
    left join intersections i
    on c.uuid = i.uuid
    group by c.uuid, c.geom

)

select *
from aggregated
