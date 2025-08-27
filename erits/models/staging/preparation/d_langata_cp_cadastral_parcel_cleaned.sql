{{ config(
    schema='Silver',
    materialized='incremental',
    unique_key= 'id',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_cadastral_parcel_clean_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH cadastre AS (
    {{ spatial_clean(
        source_ref=ref('d_langata_cp_cadastral_parcel'),
        id_column='id',
        geom_column='geom',
        aoi_ref=ref('d_langata_au_subcounty_unit_clean'),
        source_srid=4326,
        target_srid=4326,
        strategy='merge',
        filter_outside_aoi=true
    ) }}
)


/* active AS (
    SELECT *
    FROM cadastre
    WHERE current_status = 'Active'
) */

SELECT DISTINCT ON (id) *
FROM cadastre
