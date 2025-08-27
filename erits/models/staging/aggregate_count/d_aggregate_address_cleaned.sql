
{{ config(
    materialized='incremental',
    unique_key='uuid',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_aggregate_cleaned_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_aggregate_cleaned_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH clean as (
{{ spatial_clean(
  source_ref=ref('d_aggregate_address'),
  id_column='uuid',
  geom_column='geom',
  aoi_ref=ref('d_langata_au_subcounty_unit'),
  source_srid=4326,
  target_srid=4326,
  strategy='delete+insert',
  filter_outside_aoi=true,
  log_stats=true
) }}
)

SELECT DISTINCT ON  (uuid) * FROM  clean