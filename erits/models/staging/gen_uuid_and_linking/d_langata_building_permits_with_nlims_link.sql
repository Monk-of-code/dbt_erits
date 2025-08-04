{{ config(
    schema = 'Silver',
    materialized = 'table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_building_permits_nlims_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_building_permits_nlims_uuid ON {{ this }} (uuid)"
    ]
) }}

with layer as (
    select * from {{ ref('d_langata_building_permits') }}
),
cadastre as (
    select uuid, geom from {{ ref('d_langata_cp_cadastral_parcel_uuid') }}
),
joined as (
    select 
        layer.*, 
        cadastre.uuid
    from layer
    left join cadastre
    on  cadastre.geom && layer.geom
    and ST_Intersects(layer.geom, cadastre.geom)
)

select *
from joined
