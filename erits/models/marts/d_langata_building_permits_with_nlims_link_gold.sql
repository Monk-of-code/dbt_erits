{{config(
    schema = 'gold',
    materialized = 'table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildingpermitsgold_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildingpermitsgold_geom ON {{ this }} USING GIST (geom)"
    ]
) }}

with base as (
    select *
    from {{ ref('d_langata_building_permits_with_nlims_link') }}
)

select * from base