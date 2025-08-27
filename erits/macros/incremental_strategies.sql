{% macro incremental_filter(
    table_ref, 
    unique_key=none,
    updated_at_column=none,
    strategy='merge'
) %}
    {% if unique_key is none %}
        {% set unique_key = 'uuid' %}  {# Fallback default #}
    {% endif %}

    {% if is_incremental() %}
        {% if strategy == 'merge' %}
            -- Merge strategy
            select * from {{ table_ref }}
            where {{ unique_key }} not in (
                select {{ unique_key }} from {{ this }}
            )

        {% elif strategy == 'insert_only' %}
            -- Insert-only strategy
            select * from {{ table_ref }}
            where {{ unique_key }} not in (
                select {{ unique_key }} from {{ this }}
            )

        {% elif strategy == 'upsert' %}
            -- Upsert strategy
            select * from {{ table_ref }}
            where {{ unique_key }} not in (
                select {{ unique_key }} from {{ this }}
            )
            {% if updated_at_column %}
                or {{ updated_at_column }} > (
                    select coalesce(max({{ updated_at_column }}), '1900-01-01'::timestamp)
                    from {{ this }}
                )
            {% endif %}

        {% elif strategy == 'delete+insert' %}
            -- Delete+Insert strategy
            select * from {{ table_ref }}
        {% endif %}
    {% else %}
        -- Full refresh
        select * from {{ table_ref }}
    {% endif %}
{% endmacro %}