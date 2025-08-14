{{ config(
    schema='Silver',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_join_fields_geom ON {{ this }} USING GIST (geom)",
        "CREATE INDEX IF NOT EXISTS idx_join_fields_uuid ON {{ this }} (uuid)",
        "ANALYZE {{ this }}"
    ]
) }}

with cadastre as (

    select distinct ON (uuid) *
    from {{ ref('d_langata_add_trade_license_count_to_join_cadastre') }}

),

land_rate as (

    select
        uuid_derived as uuid,
        "LRNumber" as "BL_LRNumber",
        "LR Amount" as "BL_LR Amount",
        "LR Invoice No" as "BL_LR InvoiceNo",
        "Customer No" as "BL_CustomerNo",
        "Customer No1" as "BL_CustomerNo1",
        "KRA PIN" as "BL_KRAPIN",
        "Customer ID" as "BL_CustomerID",
        "Phone Number" as "BL_PhoneNumber",
        "Property Value" as "BL_PropertyValue",
        uuid_derived as "BL_uuid_derived"
    from {{ source('bronze_source', 'bd_land_rate_data') }}

),

joined as (

    select
        c.*,
        l."BL_LRNumber",
        l."BL_LR Amount",
        l."BL_LR InvoiceNo",
        l."BL_CustomerNo",
        l."BL_CustomerNo1",
        l."BL_KRAPIN",
        l."BL_CustomerID",
        l."BL_PhoneNumber",
        l."BL_PropertyValue",
        l."BL_uuid_derived"
    from cadastre c
    left join land_rate l
    on c.uuid = l.uuid

),

final as (

    select
        geom, fr_number, rim_name, lr_number, parcel_number, sheet_number, stated_area,
        area_type, comments, null_comment, reg_block, block_name, bound_type, feature_type,
        deed_plan_, county, sub_county, sub_location, dmp_number, original_number, transaction,
        old_parcel, owner, current_status, shape_leng, shape_area, dp_number, power_count,
        water_count, building_count, permit_count, address_count, uuid, "BL_LRNumber", 
        "BL_LR Amount", "BL_LR InvoiceNo", "BL_CustomerNo", "BL_CustomerNo1", "BL_KRAPIN",
        "BL_CustomerID", "BL_PhoneNumber", "BL_PropertyValue", "BL_uuid_derived", fusion, 
        property_names, rates_count, trade_count
    from joined

)

select distinct on (uuid) *
from final

