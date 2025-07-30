{{ config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_au_subcounty_unit_geom ON {{ this }} USING GIST (geom)"
    ]
) }}

SELECT *
FROM {{ source('bronze_source', 'au_subcounty_unit') }}
WHERE scouname = 'Lang''ata'
