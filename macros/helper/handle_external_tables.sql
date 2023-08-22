{% macro refresh_external_table(external_table_name, source_type) -%}
    {%- set out = "" -%} 
    {%- if source_type == 'snowflake_external_table' -%} 
        {{ dbt_external_tables.stage_external_sources(select=external_table_name) }} 
    {%- endif -%} 
    {{ return(out) }}
{%- endmacro %}       

