{{ config(
    schema = 'Silver',
    materialized = 'table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_cadastral_parcel_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_cadastral_parcel_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (
    select *
    from {{ ref('d_langata_cp_cadastral_parcel') }}
),

uuid_assigned as (
    select 
        *,
        COALESCE(
            NULLIF(TRIM(parcel_number), ''),
            NULLIF(TRIM(lr_number), ''),
            'uuid_' || id::text
        ) as uuid
    from cadastre
),

deduplicated as (
    select distinct on (uuid) *
    from uuid_assigned
    order by uuid
)

select *
from deduplicated
