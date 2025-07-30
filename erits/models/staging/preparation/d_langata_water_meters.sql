{{ config(
    schema='Silver', 
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_geom ON {{ this }} USING GIST (geom)"
    ]
 )}}

with water as (
    select *
    from {{ source('bronze_source', 'water_meters') }}
),

subcounty as (
    select *
    from {{ ref('d_langata_au_subcounty_unit') }}
),

joined as (
    select 
        w.*
    from water w
    join subcounty s
      on ST_Intersects(w.geom, s.geom)
)

select 
    *,
    (SELECT COUNT(*) FROM water) as water_count,
    (SELECT COUNT(*) FROM subcounty) as subcounty_count
from joined
