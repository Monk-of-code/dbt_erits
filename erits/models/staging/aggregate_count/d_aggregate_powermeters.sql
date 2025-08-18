{{ incremental_config('uuid') }}

{{config(
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_agg_power_customers_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_agg_power_customers_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
)}}

with power as (
    {{ incremental_filter(ref('d_langata_power_customers'), 'fid', strategy='merge') }}
),

cadastre as (
    select uuid, geom
    from {{ ref('d_langata_cp_cadastral_parcel_uuid') }}
),

intersections as (
    select
        c.uuid,
        p.geom as power_geom
    from power p
    join cadastre c
    on ST_Intersects(p.geom, c.geom)
),

aggregated as (
    select
        c.uuid,
        c.geom,
        count(i.power_geom) as power_count
    from cadastre c
    left join intersections i
    on c.uuid = i.uuid
    group by c.uuid, c.geom
)

select *
from aggregated
