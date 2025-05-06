{% macro calculate_ctr(clicks_col, impressions_col) %}
    case
        when impressions > clicks then
            round((clicks / impressions), 2)
        else 1
    end
{% endmacro %}

