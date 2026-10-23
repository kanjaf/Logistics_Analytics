
{% macro clean_text(column_name) %}
    NULLIF(
        UPPER(
            LTRIM(RTRIM(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE({{ column_name }}, ' - ', ' '),
                            '- ',
                            ' '
                        ),
                        ' -',
                        ' '
                    ),
                    '-',
                    ' '
                )
            ))
        ),
        ''
    )
{% endmacro %}
