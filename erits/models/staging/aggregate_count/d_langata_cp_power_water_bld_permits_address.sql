{{ config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_power_water_bld_permits_address_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_d_langata_cp_power_water_bld_permits_address_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (
    select *
    from {{ ref('d_langata_cp_cadastral_parcel_uuid_cleaned') }}
),

power as (
    select uuid, coalesce(power_count, 0) as power_count
    from {{ ref('d_aggregate_powermeters_cleaned') }}
),

water as (
    select uuid, coalesce(water_count, 0) as water_count
    from {{ ref('d_aggregate_watermeters_cleaned') }}
),

building as (
    select uuid, coalesce(building_count, 0) as building_count
    from {{ ref('d_aggregate_buildings_cleaned') }}
),

permit as (
    select uuid, coalesce(permit_count, 0) as permit_count
    from {{ ref('d_aggregate_developmentcontrol_cleaned') }}
),

address as (
    select uuid, coalesce(address_count, 0) as address_count
    from {{ ref('d_aggregate_address_cleaned') }}
),

joined as (
    select
        cadastre.*,
        coalesce(power.power_count, 0) as power_count,
        coalesce(water.water_count, 0) as water_count,
        coalesce(building.building_count, 0) as building_count,
        coalesce(permit.permit_count, 0) as permit_count,
        coalesce(address.address_count, 0) as address_count
    from cadastre
    left join power   on cadastre.uuid = power.uuid
    left join water   on cadastre.uuid = water.uuid
    left join building on cadastre.uuid = building.uuid
    left join permit  on cadastre.uuid = permit.uuid
    left join address on cadastre.uuid = address.uuid
)

select *,
     (case when power_count   > 0 then 1 else 0 end) +
    (case when water_count   > 0 then 1 else 0 end) +
    (case when building_count > 0 then 1 else 0 end) +
    (case when permit_count  > 0 then 1 else 0 end) +
    (case when address_count > 0 then 1 else 0 end) as fusion
 from joined
