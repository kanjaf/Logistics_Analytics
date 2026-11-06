-- Test: date_key must match full_date in YYYYMMDD format.

SELECT
    date_key,
    full_date
FROM {{ ref('dim_date') }}
WHERE date_key <> CAST(CONVERT(CHAR(8), full_date, 112) AS INT)