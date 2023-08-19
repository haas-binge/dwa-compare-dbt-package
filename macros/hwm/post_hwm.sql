{%- macro post_hwm(this) -%}

    {{ adapter.dispatch('post_hwm', 'datavault_extension')(
                      this=this
                    ) }}

{%- endmacro -%}

{% macro snowflake__post_hwm(this) %}
{% if not flags.FULL_REFRESH %}
CROSS JOIN hwm_max 
WHERE ldts > hwm_max.hwm_max_ts
{%- endif -%}
{% endmacro %}