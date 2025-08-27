
{{ config(
    materialized='incremental',
    unique_key='fid',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildings_nlims_cleaned_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildings_nlims_cleaned_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH clean as (
{{ spatial_clean(
  source_ref=ref('d_langata_building_permits_with_nlims_link'),
  id_column='fid',
  geom_column='geom',
  aoi_ref=ref('d_langata_au_subcounty_unit_clean'),
  source_srid=4326,
  target_srid=4326,
  strategy='merge',
  filter_outside_aoi=true,
  log_stats=true
) }}
)

SELECT  * FROM  clean