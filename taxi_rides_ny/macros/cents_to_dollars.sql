/*
    MACRO: safe_divide
    
    Purpose: Safely divide two numbers, returning NULL if denominator is 0
    
    Usage: {{ safe_divide('total_amount', 'trip_distance') }}
    
    This is a reusable function you can use across multiple models
*/

{% macro safe_divide(numerator, denominator, precision=2) %}
    round(
        case 
            when {{ denominator }} > 0 then {{ numerator }} / {{ denominator }}
            else null
        end, 
        {{ precision }}
    )
{% endmacro %}
