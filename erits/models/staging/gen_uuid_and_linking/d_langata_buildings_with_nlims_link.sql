
{{ config(
    schema = 'Silver',
    unique_key= 'id',
    materialized = 'incremental',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildings_nlims_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildings_nlims_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

with layer as (
    {{ incremental_filter(ref("d_langata_buildings_cleaned"), 'id', strategy='insert_only') }}
),

cadastre as (
    select uuid, geom from {{ ref('d_langata_cp_cadastral_parcel_uuid_cleaned') }}
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
