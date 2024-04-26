{%- macro insert_hwm(this, src_ldts) -%}

    {{ adapter.dispatch('insert_hwm', 'datavault_extension')(
                      this=this
                      , src_ldts=src_ldts
                    ) }}

{%- endmacro -%}
{% macro snowflake__insert_hwm(this, src_ldts) %}
INSERT INTO {{ source('LOAD_EXT_META', 'META_HWM') }} (object_name, hwm_ldts, load_date)
                       SELECT '{{ this }}',MAX({{src_ldts}} ), SYSDATE()
                       FROM {{ this }}
                       HAVING MAX({{src_ldts}}) IS NOT NULL
{% endmacro %}