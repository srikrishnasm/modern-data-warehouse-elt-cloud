{% test no_future_date(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} > CURRENT_DATE

{% endtest %}