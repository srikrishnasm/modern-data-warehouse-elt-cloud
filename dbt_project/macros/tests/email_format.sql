{% test email_format(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} NOT LIKE '%_@__%.__%'

{% endtest %}