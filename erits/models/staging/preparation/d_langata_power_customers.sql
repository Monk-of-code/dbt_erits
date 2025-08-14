{{ config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_power_customers_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with power as (
    select *
    from {{ source('bronze_source', 'power_customers') }}
),

subcounty as (
    select *
    from {{ ref('d_langata_au_subcounty_unit') }}
),

joined as (
    select 
        p.*
    from power p
    join subcounty s
      on ST_Intersects(p.geom, s.geom)
)

select * 
from joined
