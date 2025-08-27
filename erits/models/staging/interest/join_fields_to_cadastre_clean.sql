
{{ config(
    materialized='incremental',
    unique_key='id',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_joined_geom_ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_joined_cleaned_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH clean as (
{{ spatial_clean(
  source_ref=ref('join_fields_to_cadastre'),
  id_column='id',
  geom_column='geom',
  aoi_ref=ref('d_langata_au_subcounty_unit_clean'),
  source_srid=4326,
  target_srid=4326,
  strategy='merge',
  filter_outside_aoi=true,
  log_stats=true
) }}
)

SELECT * FROM  clean