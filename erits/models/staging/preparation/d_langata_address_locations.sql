{{ incremental_config('id') }}

{{ config(
    schema = 'Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_locations_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_locations_id ON {{ this }} (id)",
        "ANALYZE {{ this }}"
    ]
) }}

with addresses as (
    {{ incremental_filter(source('bronze_source', 'address'), 'id', strategy='upsert') }}
),

subcounty as (
    select *
    from {{ ref('d_langata_au_subcounty_unit') }}
),

joined as (
    select 
        a.*
    from addresses a
    join subcounty s
      on ST_Intersects(a.geom, s.geom)
)

select * 
from joined