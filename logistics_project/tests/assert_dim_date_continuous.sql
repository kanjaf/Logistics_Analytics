-- Test: dim_date contains every calendar date between its minimum and maximum dates.

WITH date_bounds AS (

    SELECT
        MIN(full_date) AS min_date,
        MAX(full_date) AS max_date,
        COUNT(*) AS actual_days
    FROM {{ ref('dim_date') }}

)

SELECT
    'Date dimension contains missing calendar dates' AS failure_reason
FROM date_bounds
WHERE actual_days <> DATEDIFF(DAY, min_date, max_date) + 1