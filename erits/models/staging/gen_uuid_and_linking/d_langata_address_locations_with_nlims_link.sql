{{ config(
    schema = 'Silver',
    unique_key= 'id',
    materialized='incremental',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_locations_nlims_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_locations_nlims_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with incremental_data as (
    {{ incremental_filter(ref('d_langata_address_cleaned'), 'id', strategy='merge') }}
),

layer as (
    select *
    from incremental_data
    where 
        -- Handle various primary address formats
        lower(accesstype) like '%primary%' 
        or 
        -- Handle various alternative address formats  
        lower(accesstype) like '%alternative%'
        or
        lower(accesstype) like '%alt%'
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

SELECT DISTINCT ON (id) *
FROM joined