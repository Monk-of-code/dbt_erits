{{ incremental_config('uuid') }}

{{ config(
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_langata_potential_interests_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

WITH cadastre AS (
   {{ incremental_filter(ref("d_langata_add_trade_license_count_to_join_cadastre"),'uuid', strategy='upsert') }}
),

land_data AS (
    SELECT *, uuid_derived AS uuid
    FROM {{ source('bronze_source', 'bd_land_rate_data') }}
),

joined AS (
    SELECT
        c.*,
        l."KRA PIN",
        l."Customer ID",
        l."Customer No",
        l."Customer No1",
        l."Phone Number",
        l."uuid_derived",
        l."Property Value",
        l."LRNumber",
        l."LR Amount",
        l."LR Invoice No"
    FROM cadastre c
    LEFT JOIN land_data l
    ON c.uuid = l.uuid
)

SELECT *
FROM joined
WHERE "KRA PIN" IS NOT NULL AND "Customer ID" IS NOT NULL AND "Customer No" IS NOT NULL
