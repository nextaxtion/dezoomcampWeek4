/*
    MACRO: get_payment_type_description
    
    Purpose: Convert payment type codes to readable descriptions
    
    This demonstrates using CASE statements in macros
*/

{% macro get_payment_type_description(payment_type_column) %}
    case {{ payment_type_column }}
        when 1 then 'Credit card'
        when 2 then 'Cash'
        when 3 then 'No charge'
        when 4 then 'Dispute'
        when 5 then 'Unknown'
        when 6 then 'Voided trip'
        else 'Unknown'
    end
{% endmacro %}
