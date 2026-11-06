
{{ config(materialized='view') }}

-- Model: dim_date
-- Grain: One row per calendar date.
-- Purpose: Shared date dimension for shipment, trip, fuel,
-- customs, tracking and delivery exception analysis.
--
-- Date range guard: Only generates dates between 2020-01-01
-- and 2030-12-31. This prevents anomalous source dates from
-- expanding the calendar unexpectedly.
--
-- Weekday calculation: 1900-01-01 was a Monday. Using this
-- fixed anchor avoids dependence on SQL Server DATEFIRST.

WITH all_dates AS (

    SELECT CAST(declaration_date AS DATE) AS date_value
    FROM {{ ref('stg_customs') }}
    WHERE declaration_date IS NOT NULL

    UNION ALL

    SELECT CAST(exception_date AS DATE)
    FROM {{ ref('stg_delivery_exceptions') }}
    WHERE exception_date IS NOT NULL

    UNION ALL

    SELECT CAST(transaction_date AS DATE)
    FROM {{ ref('stg_fuel_transactions') }}
    WHERE transaction_date IS NOT NULL

    UNION ALL

    SELECT CAST(booking_date AS DATE)
    FROM {{ ref('stg_shipments') }}
    WHERE booking_date IS NOT NULL

    UNION ALL

    SELECT CAST(expected_delivery_date AS DATE)
    FROM {{ ref('stg_shipments') }}
    WHERE expected_delivery_date IS NOT NULL

    UNION ALL

    SELECT CAST(actual_delivery_date AS DATE)
    FROM {{ ref('stg_shipments') }}
    WHERE actual_delivery_date IS NOT NULL

    UNION ALL

    SELECT CAST(event_timestamp AS DATE)
    FROM {{ ref('stg_tracking_events') }}
    WHERE event_timestamp IS NOT NULL

),

date_bounds AS (

    SELECT
        MIN(date_value) AS min_date,
        MAX(date_value) AS max_date
    FROM all_dates

),

digits AS (

    SELECT n
    FROM (VALUES
        (0), (1), (2), (3), (4),
        (5), (6), (7), (8), (9)
    ) AS d(n)

),

numbers AS (

    SELECT
        d1.n
        + (d2.n * 10)
        + (d3.n * 100)
        + (d4.n * 1000) AS day_offset
    FROM digits d1
    CROSS JOIN digits d2
    CROSS JOIN digits d3
    CROSS JOIN digits d4

),

date_series AS (

    SELECT
        DATEADD(DAY, n.day_offset, db.min_date) AS date_value
    FROM date_bounds db
    CROSS JOIN numbers n
    WHERE
        db.min_date IS NOT NULL
        AND db.max_date IS NOT NULL
        AND db.min_date >= CONVERT(DATE, '20200101', 112)
        AND db.max_date <= CONVERT(DATE, '20301231', 112)
        AND DATEDIFF(DAY, db.min_date, db.max_date) < 10000
        AND DATEADD(DAY, n.day_offset, db.min_date) <= db.max_date

),

calendar AS (

    SELECT
        date_value,

        -- Monday = 1, Tuesday = 2, ..., Sunday = 7.
        (DATEDIFF(DAY, '19000101', date_value) % 7) + 1
            AS day_of_week

    FROM date_series

)

SELECT
    CAST(CONVERT(CHAR(8), date_value, 112) AS INT) AS date_key,
    date_value AS full_date,

    DAY(date_value) AS day_number,

    CASE day_of_week
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END AS day_name,

    day_of_week,

    -- Monday-based week start for weekly reporting.
    DATEADD(DAY, 1 - day_of_week, date_value) AS week_start_date,

    DAY(EOMONTH(date_value)) AS days_in_month,
    DATEPART(DAYOFYEAR, date_value) AS day_of_year,

    MONTH(date_value) AS month_number,

    CASE MONTH(date_value)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_name,

    LEFT(
        CASE MONTH(date_value)
            WHEN 1 THEN 'January'
            WHEN 2 THEN 'February'
            WHEN 3 THEN 'March'
            WHEN 4 THEN 'April'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
            WHEN 7 THEN 'July'
            WHEN 8 THEN 'August'
            WHEN 9 THEN 'September'
            WHEN 10 THEN 'October'
            WHEN 11 THEN 'November'
            WHEN 12 THEN 'December'
        END,
        3
    ) AS month_name_short,

    MONTH(date_value) AS month_number_sort,

    YEAR(date_value) * 100 + MONTH(date_value) AS year_month_sort,

    DATEPART(QUARTER, date_value) AS quarter_number,
    CONCAT('Q', DATEPART(QUARTER, date_value)) AS quarter_name,

    YEAR(date_value) AS year_number,

    CONCAT(
        YEAR(date_value),
        '-',
        RIGHT('0' + CAST(MONTH(date_value) AS VARCHAR(2)), 2)
    ) AS year_month,

    CONCAT(
        YEAR(date_value),
        '-Q',
        DATEPART(QUARTER, date_value)
    ) AS year_quarter,

    CASE
        WHEN date_value = EOMONTH(date_value) THEN 1
        ELSE 0
    END AS is_month_end,

    CASE
        WHEN day_of_week IN (6, 7) THEN 1
        ELSE 0
    END AS is_weekend

FROM calendar
