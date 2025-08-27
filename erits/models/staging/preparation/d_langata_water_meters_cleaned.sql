
{{ config(
    materialized='incremental',
    schema='Silver', 
    unique_key='fid',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_cleaned_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_water_meters_cleaned_fid ON {{ this }} (fid)",
        "ANALYZE {{ this }}"
    ]
)}}


{{ spatial_clean(
  source_ref=ref('d_langata_water_meters'),
  id_column='fid',
  geom_column='geom',
  aoi_ref=ref('d_langata_au_subcounty_unit_clean'),
  source_srid=4326,
  target_srid=4326,
  strategy='merge',
  filter_outside_aoi=true,
  log_stats=true
) }}