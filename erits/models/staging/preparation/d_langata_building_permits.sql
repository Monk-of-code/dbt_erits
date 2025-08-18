{{ incremental_config('fid') }}

{{ config(
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_building_permits_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_building_permits_fid ON {{ this }} (fid)",
        "ANALYZE {{ this }}"
    ]
) }}

with permits as (
    {{ incremental_filter(source('bronze_source', 'building_permits'), 'fid', strategy='merge') }}
),

subcounty as (
    select *
    from {{ ref('d_langata_au_subcounty_unit') }}
),

joined as (
    select 
        p.*
    from permits p
    join subcounty s
      on ST_Intersects(p.geom, s.geom)
)

select * 
from joined