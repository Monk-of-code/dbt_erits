{{config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
)}}

with addresses as (

    select *
    from {{ ref('d_langata_address_locations') }}

),

cadastre as (

    select uuid, geom
    from {{ ref('d_langata_cp_cadastral_parcel_uuid') }}

),

intersections as (

    select
        c.uuid,
        a.geom as addresses_geom
    from addresses a
    join cadastre c
    on ST_Intersects(a.geom, c.geom)

),

aggregated as (

    select
        c.uuid,
        c.geom,
        count(i.addresses_geom) as address_count
    from cadastre c
    left join intersections i
    on c.uuid = i.uuid
    group by c.uuid, c.geom

)

select *
from aggregated
