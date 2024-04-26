{%- macro get_attribute_definition(attribute_dict, attribute_type, definition_type, attribute_name) -%}

    {{ adapter.dispatch('get_attribute_definition', 'datavault_extension')(
                          attribute_dict=attribute_dict
                        , attribute_type=attribute_type
                        , definition_type=definition_type
                        , attribute_name=attribute_name
                    ) }}

{%- endmacro -%}

{% macro snowflake__get_attribute_definition(attribute_dict, attribute_type, definition_type, attribute_name) -%}

{%- set out_attribute =  "" -%}
{%- set attribute_name_raw = ('"' ~ attribute_name ~ '_raw"')|upper -%}
{%- set attribute_name = ('"' ~ attribute_name ~ '"')|upper -%}
{%- if definition_type == 'raw' -%}
    {%- if attribute_type in ['default','additional'] -%}
        {%- set out_attribute =  'TRIM(' ~ attribute_dict["value"] ~ '::STRING) as ' ~attribute_name_raw -%}
    {%- elif attribute_type in ['payload'] -%}
        {%- if attribute_dict["data_type"]=="NUMBER" -%}
            {%- set decimal_separator = attribute_dict["decimal_separator"] -%}
            {%- set out_attribute =  "TRIM(value:c" ~ attribute_dict["source_column_number"] ~ "::STRING) " -%}
            {%- set out_attribute =  "REPLACE(" ~ out_attribute ~ ", ',', '" ~ decimal_separator ~ "')" -%}
            {%- set out_attribute =  out_attribute ~ " as " ~ attribute_name_raw -%}
        {%- else -%}
            {%- set out_attribute =  "TRIM(value:c" ~ attribute_dict["source_column_number"] ~ "::STRING) as " ~ attribute_name_raw -%}
        {%- endif -%}
     {%- endif -%}
{%- elif definition_type == 'typed' -%}
    {%- set data_type =  attribute_dict["data_type"]|upper -%}
    {%- if attribute_dict["format"] | trim == "" -%}
        {%- set data_format = "" -%}
    {%- else -%}
        {%- if data_type in ["TIMESTAMP","DATE"] -%}
            {%- set data_format =  ", '" ~ attribute_dict["format"] ~ "'" -%}
        {%- elif data_type in ["NUMBER"] -%}
            {%- set data_format =  ", " ~ attribute_dict["format"] ~ "" -%}
        {%- endif -%}
    {%- endif -%}

    {%- if data_type in ["TIMESTAMP","DATE","NUMBER"] -%}
        {%- set out_attribute =  "TRY_TO_" ~ data_type ~ "(" ~ attribute_name_raw ~ data_format ~ ") as " ~ attribute_name -%}
    {%- else -%}
        {%- set out_attribute =  attribute_name_raw ~ " as " ~ attribute_name -%}
    {%- endif -%}

{%- elif definition_type == 'type_check' -%}
    {%- set data_type =  attribute_dict["data_type"]|upper -%}
    {%- set data_format =  attribute_dict["format"] -%}
    {%- if not attribute_dict["type_check"] == "" -%} 
        {%- set type_check=True -%} 
    {%- else -%} 
        {%- set type_check=attribute_dict["type_check"] -%} 
    {%- endif -%} 
    {%- if attribute_dict["format"] | trim == "" -%}
        {%- set data_format = "" -%}
    {%- else -%}
        {%- if data_type in ["TIMESTAMP","DATE"] -%}
            {%- set data_format =  ", '" ~ attribute_dict["format"] ~ "'" -%}
        {%- elif data_type in ["NUMBER"] -%}
            {%- set data_format =  ", " ~ attribute_dict["format"] ~ "" -%}
        {%- endif -%}
    {%- endif -%}

    {%- if data_type in ["TIMESTAMP","DATE","NUMBER"] and type_check -%}    
            {%- set check_name = ('"is_' ~ attribute_name |replace('"','')  ~ '_type_ok"') | upper -%} 
            {%- set out_attribute =  "TRY_TO_" ~ data_type ~ "(" ~ attribute_name_raw ~ data_format ~ ") IS NOT NULL OR " ~ attribute_name_raw ~ " IS NULL as " ~ check_name -%}
    {%- endif -%}
 
{%- endif -%}
{{ return(out_attribute) }}
{%- endmacro %}

{% macro get_dubcheck(dub_check_list, dub_check_name) -%}
    
    {%- set out_dubcheck = datavault_extension.format_list(dub_check_list,0,"," ) -%}
    {%- set out_dubcheck = "ROW_NUMBER() OVER (PARTITION BY " ~ out_dubcheck ~  " ORDER BY " ~ out_dubcheck ~  ') = 1 AS "' ~ dub_check_name |upper ~ '"' -%}
    {{ return(out_dubcheck) }}    
{%- endmacro %}

{% macro get_keycheck(keycheck_list, definition_type) -%}
    {%- set out_keycheck_list = [] -%}

    {%- for attribute in keycheck_list -%}
        {%- set attribute_name_raw = ('"' ~ attribute ~ '_raw"')|upper -%}
        {%- set key_check_name = ('"is_' ~ attribute ~ '_key_check_ok"')|upper -%}
        {%- set keycheck = "COALESCE(" ~ attribute_name_raw ~ ", '') <> '' as " ~ key_check_name -%}
        {{ out_keycheck_list.append(keycheck) }}
    {%- endfor -%}
    {{ return(out_keycheck_list) }}    
{%- endmacro %}


{% macro get_attribute_definition_list(dict, attribute_type, definition_type) -%}
    {%- set out_attribute_list = [] -%}
    {%- for attribute in dict -%}
        {%- set out_attribute = datavault_extension.get_attribute_definition(dict[attribute], attribute_type, definition_type, attribute) -%}
        {%- if out_attribute != "" -%}
            {{ out_attribute_list.append(out_attribute) }}
        {%- endif -%}
    {%- endfor -%}

    {{ return(out_attribute_list) }}
{%- endmacro %}


{% macro format_list(attribute_list, spacenumber=0,separator="\ns, ") -%}
    {%- set spaces = "    " * spacenumber -%}
    {%- set separator = separator | replace("s", spaces * spacenumber)  -%}
    {%- set out_attribute_list = attribute_list|join(separator) -%}
    {{ return(out_attribute_list) }}
{%- endmacro %}

{% macro format_string(attribute, spacenumber=0,separator="\ns ") -%}
    {%- set spaces = "    " * spacenumber -%}
    {%- set separator = separator | replace("s", spaces * spacenumber)  -%}
    {%- set out_attribute = separator ~ attribute -%}
    {{ return(out_attribute) }}
{%- endmacro %}

{% macro add_attribute_from_dict_to_checks_list(dict, attribute_list, out_type) -%}
    {%- for attribute in dict -%}
        {%- if not attribute["type_check"] == "" -%} 
            {%- set type_check=True -%} 
        {%- else -%} 
            {%- set type_check=attribute["type_check"] -%} 
        {%- endif -%} 
        {%- if dict[attribute]["data_type"] in ["TIMESTAMP","DATE","NUMBER"] and type_check -%}
            {%- if out_type == "all_chk" -%}
            {%- set type_check_name = ('"is_' ~ attribute ~ '_type_ok"') |upper -%}
            {{ attribute_list.append(type_check_name) }}
            {%- elif out_type == "all_msg" -%}
            {%- set attribute_name_raw = ('"' ~ attribute ~ '_raw"')|upper -%}
            {%- set attribute_check_dict = '#{"' ~ attribute ~ '":"# || COALESCE(TO_VARCHAR(' ~ attribute_name_raw ~ ') ,##) || #"}#' -%}
            {%- set attribute_check_dict = attribute_check_dict | replace("#", "'") -%}
            {%- set type_check_name = ('"is_' ~ attribute ~ '_type_ok"') |upper -%}
            {{ attribute_list.append('IFF(NOT ' ~ type_check_name ~ "," ~ attribute_check_dict ~ ",'')") }}

            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(attribute_list) }}
{%- endmacro %}
{% macro add_attribute_from_list_to_checks_list(check_type_attribute_list, attribute_list, check_type) -%}
    {%- for attribute in check_type_attribute_list -%}
        {%- set type_check_name = ('"is_' ~ attribute ~ check_type ~ '_ok"') |upper -%}
        {{ attribute_list.append(type_check_name) }}
    {%- endfor -%}
    {{ return(attribute_list) }}
{%- endmacro %}

{% macro add_item_to_list(list, item) -%}
    {{ list.append(item) }}
    {{ return(list) }}
{%- endmacro %}

