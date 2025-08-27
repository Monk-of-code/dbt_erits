

{{ config(
    materialized='incremental',
    unique_key='id',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_clean_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_address_clean_id ON {{ this }} (id)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH clean as (
{{ spatial_clean(
  source_ref=ref('d_langata_address_locations'),
  id_column='id',
  geom_column='geom',
  aoi_ref=ref('d_langata_au_subcounty_unit_clean'),
  source_srid=4326,
  target_srid=4326,
  strategy='delete+insert',
  filter_outside_aoi=true
) }}
)

SELECT DISTINCT ON  (id) * FROM  clean