{{ incremental_config('uuid') }}
{{ config(
    materialized='table',
    schema='Silver',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_propnames_uuid ON {{ this }} (uuid)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_propnames_geom ON {{ this }} USING GIST (geom)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (
    select *
    from {{ ref('d_langata_cp_power_water_bld_permits_address') }}
),

address as (
    select *
    from {{ ref('d_langata_address_locations') }}
),


joined as (
    select
        c.uuid,
        c.geom,
        a.propertyna
    from cadastre c
    left join address a
    on ST_Intersects(c.geom, a.geom)
    where a.propertyna is not null
),

classified as (
    select
        uuid,
        propertyna,
        case
            when levenshtein(lower(propertyna), 'commercial') <= 4 then 'Commercial'
            when levenshtein(lower(propertyna), 'estate') <= 4 then 'Estate'
            when levenshtein(lower(propertyna), 'mixed use') <= 4 then 'Mixed Use'
            when levenshtein(lower(propertyna), 'residential') <= 4 then 'Residential'
            else initcap(propertyna)
        end as clean_propertyna
    from joined
),


property_names as (
    select
        uuid,
        string_agg(distinct clean_propertyna, ', ' order by clean_propertyna) as property_names
    from classified
    group by uuid
),


deduped_cadastre as (
    select distinct on (uuid) *
    from cadastre
),

final as (
    select
        dc.*,
        pn.property_names
    from deduped_cadastre dc
     left join property_names pn using (uuid)
)


select *
from final
