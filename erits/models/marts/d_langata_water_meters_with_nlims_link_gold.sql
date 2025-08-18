{{ incremental_config('uuid') }}

{{ config(
    schema = 'gold',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_wateremetersgold_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_wateremetersgold_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with base as (
    {{ incremental_filter(ref('d_langata_water_meters_with_nlims_link'), 'uuid', strategy='upsert') }}
)

select * from base