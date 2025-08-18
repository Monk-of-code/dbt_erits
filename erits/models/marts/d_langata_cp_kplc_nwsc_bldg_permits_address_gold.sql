{{ incremental_config('uuid') }}

{{ config(
    schema='gold',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_kplc_nwsc_bldg_permits_address_gold_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_kplc_nwsc_bldg_permits_address_gold_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with base as (
    {{ incremental_filter(ref('d_langata_cp_power_water_bld_permits_add_name'), 'uuid', strategy='merge') }}
)

select *
from base
