
{{ config(
    materialized='incremental',
    unique_key='uuid',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata__tradelicensecountcleaned_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_tradelicensecleaned_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH clean as (
{{ spatial_clean(
  source_ref=ref('d_langata_add_trade_license_count_to_join_cadastre'),
  id_column='uuid',
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