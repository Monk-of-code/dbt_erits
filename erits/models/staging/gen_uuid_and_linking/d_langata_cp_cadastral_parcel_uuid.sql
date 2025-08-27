{{ config(
    schema = 'Silver',
    materialized = 'table',
    pre_hook=[
        "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""
    ],
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_cadastral_parcel_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_cadastral_parcel_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (
    select *
    from {{ ref('d_langata_cp_cadastral_parcel_cleaned') }}
),

uuid_assigned as (
    select 
        *,
        uuid_generate_v5(
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
            concat_ws('||','cadastre',id::text)
        )
        as uuid
    from cadastre
),

deduplicated as (
    select distinct on (uuid) *
    from uuid_assigned
    order by uuid
)

select distinct on (uuid) *
from deduplicated
