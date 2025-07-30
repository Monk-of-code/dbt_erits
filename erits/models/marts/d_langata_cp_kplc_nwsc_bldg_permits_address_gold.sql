{{ config(
    schema='gold',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_kplc_nwsc_bldg_permits_address_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_kplc_nwsc_bldg_permits_address_geom ON {{ this }} USING GIST (geom)"
    ]
) }}

WITH base AS (
    SELECT *
    FROM {{ ref('join_fields_to_cadastre') }}
)

SELECT * FROM base
