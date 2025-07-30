{{ config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_cadastral_parcel_geom ON {{ this }} USING GIST (geom)"
    ]
) }}

WITH cadastre AS (
    SELECT *
    FROM {{ source('bronze_source', 'cp_cadastral_parcel') }}
),

subcounty AS (
    SELECT *
    FROM {{ ref('d_langata_au_subcounty_unit') }}
),

joined AS (
    SELECT 
        c.*
    FROM cadastre c
    JOIN subcounty s
      ON ST_Intersects(c.geom, s.geom)
),

active AS (
    SELECT *
    FROM joined
    WHERE current_status = 'Active'
)

SELECT DISTINCT * 
FROM active
