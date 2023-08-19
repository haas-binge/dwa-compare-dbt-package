{% macro autoexec() %}

{{ print_current() }}

{{ create_extra_schemas() }} 

{{ create_table_meta_hwm() }}

{% endmacro %}

