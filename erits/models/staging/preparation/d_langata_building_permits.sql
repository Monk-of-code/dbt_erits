{{config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_building_permits_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
)}}

WITH permits AS(
    SELECT *
    FROM {{source ('bronze_source','building_permits')}}
),

subcounty AS (
    SELECT *
    FROM {{ref('d_langata_au_subcounty_unit')}}
),

joined AS (
    SELECT 
    p. *
    FROM permits p
    JOIN subcounty s
      ON ST_Intersects(p.geom,s.geom)
)

SELECT * 
FROM joined