{% macro incremental_config(unique_key='uuid') %}
    {{ config(
        materialized='incremental',
        unique_key=unique_key,
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    ) }}
{% endmacro %}

{% macro incremental_filter(
    table_ref, 
    unique_key='uuid', 
    updated_at_column=none,
    strategy='merge'
) %}
    {% if is_incremental() %}
        {% if strategy == 'merge' %}
            -- Merge strategy: handles all business rules automatically
            -- Unique key check, Insert new rows, Update changed rows
            -- Handle schema drift, Deduplicate
            select * from {{ table_ref }}
            
        {% elif strategy == 'insert_only' %}
            -- Insert-only strategy: only process new records
            -- Use when you only want new data, no updates
            select * from {{ table_ref }}
            where {{ unique_key }} not in (
                select {{ unique_key }} 
                from {{ this }}
            )
            
        {% elif strategy == 'upsert' %}
            -- Upsert strategy: process new and updated records
            -- Good for data with timestamps that need updates
            select * from {{ table_ref }}
            where {{ unique_key }} not in (
                select {{ unique_key }} 
                from {{ this }}
            )
            {% if updated_at_column %}
                or {{ updated_at_column }} > (
                    select coalesce(max({{ updated_at_column }}), '1900-01-01'::timestamp)
                    from {{ this }}
                )
            {% endif %}
        {% endif %}
    {% else %}
        -- Full refresh: process all records
        select * from {{ table_ref }}
    {% endif %}
{% endmacro %}