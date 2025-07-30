{{ config(
    schema='gold',
    materialized='table',
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_d_potential_interest_to_cadastre_uuid ON {{ this }} (uuid)"   
    ]
) }}

WITH base AS (
    SELECT *
    FROM {{ ref('d_langata_potential_interests_to_land') }}
),

cleaned AS (
    SELECT
        lr_number,
        parcel_number,
        uuid,
        "LRNumber" AS BL_LRNumber,
        "LR Amount" AS BL_LRAmount,
        "LR Invoice No" AS BL_LRInvoiceNo,
        "Customer No" AS BL_CustomerNo,
        "Customer No1" AS BL_CustomerNo1,
        "KRA PIN" AS BL_KRAPIN,
        "Customer ID" AS BL_CustomerID,
        "Phone Number" AS BL_PhoneNumber,
        uuid_derived AS BL_uuid_derived,
        "Property Value" AS BL_PropertyValue
    FROM base
)

SELECT * FROM cleaned
