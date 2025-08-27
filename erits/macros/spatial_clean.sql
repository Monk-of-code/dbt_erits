{% macro spatial_clean(
    source_ref,                 
    id_column='id',
    geom_column='geom',
    aoi_ref=ref('d_langata_au_subcounty_unit'),
    source_srid=4326,
    target_srid=4326,
    strategy='merge',            
    filter_outside_aoi=true,
    log_stats=false              
) %}


{# Basic compile-time logging of parameters #}
{% do log(
    "spatial_clean: start | src=" ~ source_ref ~
    " id_col=" ~ id_column ~
    " geom_col=" ~ geom_column ~
    " src_srid=" ~ source_srid ~
    " tgt_srid=" ~ target_srid ~
    " strategy=" ~ strategy ~
    " filter_outside_aoi=" ~ filter_outside_aoi ~
    " log_stats=" ~ log_stats,
    info=True
) %}

{# Optional runtime stats (guarded to only execute during dbt run, not compile) #}
{% if log_stats and execute %}
  {# Count source rows #}
  {% set src_count_sql = "select count(*) as c from " ~ source_ref %}
  {% set src_count_tbl = run_query(src_count_sql) %}
  {% if src_count_tbl is not none %}
    {% set src_count = src_count_tbl.columns[0].values()[0] %}
    {% do log("spatial_clean: source row_count=" ~ src_count, info=True) %}
  {% endif %}

  {% if filter_outside_aoi %}
  {# Count AOI rows #}
  {% set aoi_count_sql = "select count(*) as c from " ~ aoi_ref %}
  {% set aoi_count_tbl = run_query(aoi_count_sql) %}
  {% if aoi_count_tbl is not none %}
    {% set aoi_count = aoi_count_tbl.columns[0].values()[0] %}
    {% do log("spatial_clean: aoi row_count=" ~ aoi_count, info=True) %}
  {% endif %}
  {% endif %}

  {# SRID distribution (top) #}
  {% set srid_sql = "select coalesce(ST_SRID(\"" ~ geom_column ~ "\"),0) as srid, count(*) cnt from " ~ source_ref ~ " group by 1 order by 2 desc limit 5" %}
  {% set srid_tbl = run_query(srid_sql) %}
  {% if srid_tbl is not none and srid_tbl.rows|length > 0 %}
    {% set srid_pairs = [] %}
    {% for r in srid_tbl.rows %}
      {% do srid_pairs.append(r[0]|string ~ ":" ~ r[1]|string) %}
    {% endfor %}
    {% do log("spatial_clean: srid_distribution(top)=" ~ (srid_pairs|join(",")), info=True) %}
  {% endif %}

  {# Geometry type distribution (top) #}
  {% set gtype_sql = "select GeometryType(\"" ~ geom_column ~ "\") as gtype, count(*) cnt from " ~ source_ref ~ " group by 1 order by 2 desc limit 5" %}
  {% set gtype_tbl = run_query(gtype_sql) %}
  {% if gtype_tbl is not none and gtype_tbl.rows|length > 0 %}
    {% set gtype_pairs = [] %}
    {% for r in gtype_tbl.rows %}
      {% do gtype_pairs.append((r[0] if r[0] is not none else 'NULL') ~ ":" ~ r[1]|string) %}
    {% endfor %}
    {% do log("spatial_clean: geometry_types(top)=" ~ (gtype_pairs|join(",")), info=True) %}
  {% endif %}

  {# Per-step pipeline counts (respecting incremental_filter) #}
  {% set stats_sql %}
with
{% if filter_outside_aoi %}
  aoi as (
      select ST_Subdivide(ST_UnaryUnion(ST_MakeValid(geom)), 256) as geom
      from {{ aoi_ref }}
  ),
{% endif %}
  base as (
      {{ incremental_filter(
          table_ref=source_ref,
          unique_key=id_column,
          strategy=strategy
      ) }}
  ),
  geom_ops as (
      select
          {{ id_column }} as id,
          case
              when ST_SRID({{ geom_column }}) is null or ST_SRID({{ geom_column }}) = 0
                  then ST_SetSRID({{ geom_column }}, {{ source_srid }})
              else {{ geom_column }}
          end as geom_with_srid
      from base
  ),
  reproj as (
      select
          id,
          case
              when ST_SRID(geom_with_srid) != {{ target_srid }}
                  then ST_Transform(geom_with_srid, {{ target_srid }})
              else geom_with_srid
          end as geom_proj
      from geom_ops
  ),
  repaired as (
      select id, ST_MakeValid(geom_proj) as geom_valid from reproj
  ),
  oriented as (
      select
          id,
          case
              when GeometryType(geom_valid) in ('POLYGON','MULTIPOLYGON')
                  then ST_ForcePolygonCW(geom_valid)
              else geom_valid
          end as geom_oriented
      from repaired
  ),
  filtered as (
      select id, geom_oriented
      from oriented
      where geom_oriented is not null
        and ST_IsValid(geom_oriented)
        and not ST_IsEmpty(geom_oriented)
  ),
{% if filter_outside_aoi %}
  with_aoi as (
      select distinct f.id
      from filtered f
      join aoi a on f.geom_oriented && a.geom and ST_Intersects(f.geom_oriented, a.geom)
  )
  select
    (select count(*) from base)       as base_count,
    (select count(*) from filtered)   as filtered_count,
    (select count(*) from with_aoi)   as with_aoi_count
{% else %}
  with_aoi as (
      select distinct f.id from filtered f
  )
  select
    (select count(*) from base)       as base_count,
    (select count(*) from filtered)   as filtered_count,
    (select count(*) from filtered)   as with_aoi_count
{% endif %}
  {% endset %}

  {% set stats_tbl = run_query(stats_sql) %}
  {% if stats_tbl is not none and stats_tbl.rows|length == 1 %}
    {% set base_count = stats_tbl.rows[0][0] %}
    {% set filtered_count = stats_tbl.rows[0][1] %}
    {% set with_aoi_count = stats_tbl.rows[0][2] %}
    {% set dropped_invalid = (base_count | int) - (filtered_count | int) %}
    {% set dropped_outside_aoi = (filtered_count | int) - (with_aoi_count | int) %}
    {% do log(
      "spatial_clean: pipeline_counts | base=" ~ base_count ~
      " | after_valid_filter=" ~ filtered_count ~
      " | after_aoi=" ~ with_aoi_count,
      info=True
    ) %}
    {% if filter_outside_aoi %}
    {% do log(
      "spatial_clean: rows_dropped | invalid_or_empty=" ~ dropped_invalid ~
      " | outside_aoi=" ~ dropped_outside_aoi,
      info=True
    ) %}
    {% else %}
    {% do log(
      "spatial_clean: rows_dropped | invalid_or_empty=" ~ dropped_invalid ~
      " | aoi_filtering_disabled",
      info=True
    ) %}
    {% endif %}
  {% endif %}
{% endif %}

{%- set cols = adapter.get_columns_in_relation(source_ref) -%}
{%- set select_cols = [] -%}
{%- for col in cols -%}
  {%- if col.name|lower not in [geom_column|lower] -%}
    {%- do select_cols.append('b."' ~ col.name ~ '"') -%}
  {%- endif -%}
{%- endfor -%}

with
{% if filter_outside_aoi %}
  aoi as (
      select ST_Subdivide(ST_UnaryUnion(ST_MakeValid(geom)), 256) as geom
      from {{ aoi_ref }}
  ),
{% endif %}
  base as (
      {{ incremental_filter(
          table_ref=source_ref, 
          unique_key=id_column,  
          strategy=strategy
      ) }}
  ),


-- Step 1: only id + geom go through heavy spatial ops
  geom_ops as (
      select
          {{ id_column }} as id,
          case
              when ST_SRID({{ geom_column }}) is null or ST_SRID({{ geom_column }}) = 0
                  then ST_SetSRID({{ geom_column }}, {{ source_srid }})
              else {{ geom_column }}
          end as geom_with_srid
      from base
  ),
  reproj as (
      select
          id,
          case
              when ST_SRID(geom_with_srid) != {{ target_srid }}
                  then ST_Transform(geom_with_srid, {{ target_srid }})
              else geom_with_srid
          end as geom_proj
      from geom_ops
  ),
  repaired as (
      select
          id,
          ST_MakeValid(geom_proj) as geom_valid
      from reproj
  ),
  oriented as (
      select
          id,
          case
              when GeometryType(geom_valid) in ('POLYGON','MULTIPOLYGON')
                  then ST_ForcePolygonCW(geom_valid)
              else geom_valid
          end as geom_oriented
      from repaired
  ),
  filtered as (
      select id, geom_oriented
      from oriented
      where geom_oriented is not null
        and ST_IsValid(geom_oriented)
        and not ST_IsEmpty(geom_oriented)
  ),
{% if filter_outside_aoi %}
  with_aoi as (
      select distinct f.id, f.geom_oriented
      from filtered f
      join aoi a
        on f.geom_oriented && a.geom   -- bounding box first (index use)
       and ST_Intersects(f.geom_oriented, a.geom)
  )
{% else %}
  with_aoi as (
      select distinct f.id, f.geom_oriented
      from filtered f
  )
{% endif %}

-- Step 2: join back all original columns + cleaned geom
select
    {{ select_cols | join(',\n  ') }},
    g.geom_oriented as geom
from base b
join with_aoi g
  on b."{{ id_column }}" = g.id

{% do log("spatial_clean: end | src=" ~ source_ref, info=True) %}
{% endmacro %}
