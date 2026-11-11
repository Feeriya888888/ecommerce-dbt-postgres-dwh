{% macro cents_to_currency(column_name, scale=2) %}
    ROUND(CAST({{ column_name }} AS NUMERIC) / 100.0, {{ scale }})
{% endmacro %}
