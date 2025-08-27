
{{ config(
    materialized='incremental',
    schema='Silver', 
    unique_key='fid',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_fid ON {{ this }} (fid)",
        "ANALYZE {{ this }}"
    ]
)}}

with water as (
    {{ incremental_filter(source('bronze_source', 'water_meters'), 'fid', strategy='delete+insert') }}
),

subcounty as (
    select *
    from {{ ref('d_langata_au_subcounty_unit_clean') }}
),

joined as (
    select 
        w.*
    from water w
    join subcounty s
      on ST_Intersects(w.geom, s.geom)
)

select distinct on (fid) * 
from joined