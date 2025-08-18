{{ incremental_config('id') }}

{{config(
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildings_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_buildings_fid ON {{ this }} (id)",
        "ANALYZE {{ this }}"
    ]
)}}

WITH buildings AS (
    {{ incremental_filter(source('bronze_source', 'buildings_183'), 'id', strategy='merge') }}
),

subcounty AS (
    SELECT geom AS subcounty_geom
    FROM {{ ref('d_langata_au_subcounty_unit') }}
),

joined AS (
    SELECT 
        b.* 
    FROM buildings b
    JOIN subcounty s
      ON ST_Intersects(b.geom, s.subcounty_geom)
)

SELECT *
FROM joined
