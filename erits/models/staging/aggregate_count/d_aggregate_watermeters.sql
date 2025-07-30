{{config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_geom ON {{ this }} USING GIST (geom)"
    ]
)}}

with water as (

    select *
    from {{ ref('d_langata_water_meters') }}

),

cadastre as (

    select uuid, geom
    from {{ ref('d_langata_cp_cadastral_parcel_uuid') }}

),

intersections as (

    select
        c.uuid,
        w.geom as water_geom
    from water w
    join cadastre c
    on ST_Intersects(w.geom, c.geom)

),

aggregated as (

    select
        c.uuid,
        c.geom,
        count(i.water_geom) as water_count
    from cadastre c
    left join intersections i
    on c.uuid = i.uuid
    group by c.uuid, c.geom

)

select *
from aggregated
