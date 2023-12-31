{%- macro pre_hwm(this,omit_with=false, add_comma_at_end=false) -%}

    {{ adapter.dispatch('pre_hwm', 'datavault_extension')(
                        this=this
                      , omit_with=omit_with
                      , add_comma_at_end=add_comma_at_end
                    ) }}

{%- endmacro -%}

{%- macro snowflake__pre_hwm(this, omit_with, add_comma_at_end) -%}
{%- if not flags.FULL_REFRESH -%}
    {%- if not omit_with -%}WITH{%- endif -%} hwm as
    (
        select max(hwm_ldts) hwm_max_ts from {{ source('LOAD_EXT_META', 'META_HWM') }} where object_name = '{{ this }}'
    ),
    hwm_max AS
    (
        select COALESCE(hwm.hwm_max_ts,to_timestamp('01.01.1900','DD.MM.YYYY') ) hwm_max_ts from hwm
    ){%- if add_comma_at_end -%},{%- endif -%}
{%- else -%}
{%- endif -%}
{%- endmacro -%}