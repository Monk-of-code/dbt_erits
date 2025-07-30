{{config(
    schema = 'gold',
    materialized = 'table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_powercustomersgold_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_powercustomersgold_geom ON {{ this }} USING GIST (geom)"
    ]
) }}

with base as (
    select *
    from {{ ref('d_langata_power_customers_with_nlims_link') }}
)

select * from base