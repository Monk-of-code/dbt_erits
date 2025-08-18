{{ incremental_config('uuid') }}

{{config(
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_aggregate_buildings ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_aggregate_buildings_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
)}}

with buildings as (
    {{ incremental_filter(ref('d_langata_buildings'), 'id', strategy='merge') }}
),

cadastre as (
    select uuid, geom
    from {{ ref('d_langata_cp_cadastral_parcel_uuid') }}
),

intersections as (
    select
        c.uuid,
        b.geom as building_geom
    from buildings b
    join cadastre c
    on ST_Intersects(b.geom, c.geom)
),

aggregated as (
    select
        c.uuid,
        c.geom,
        count(i.building_geom) as building_count
    from cadastre c
    left join intersections i
    on c.uuid = i.uuid
    group by c.uuid, c.geom
)

select *
from aggregated
