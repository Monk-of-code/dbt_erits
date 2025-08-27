

{{ config(
    materialized='incremental',
    schema='Silver',
    unique_key='fid',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_power_customers_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_power_customers_fid ON {{ this }} (fid)",
        "ANALYZE {{ this }}"
    ]
) }}

with power as (
    {{ incremental_filter(source('bronze_source','power_customers'), 'fid', strategy='merge') }}
),

subcounty as (
    select *
    from {{ ref('d_langata_au_subcounty_unit_clean') }}
),

joined as (
    select 
        p.*
    from power p
    join subcounty s
      on ST_Intersects(p.geom, s.geom)
)

select distinct on (fid) * 
from joined