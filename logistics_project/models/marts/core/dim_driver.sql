{{ config(materialized='view') }}

-- Model: dim_driver
-- Grain: One row per driver, including one UNKNOWN member.
-- Purpose: Driver attributes for logistics performance analysis.

SELECT
    driver_id,
    driver_name,
    gender,
    hire_date,
    experience_years,
    license_class,
    home_city,
    safety_score
FROM {{ ref('stg_drivers') }}

UNION ALL

SELECT
    CAST('UNKNOWN' AS NVARCHAR(50)) AS driver_id,
    CAST('Unknown' AS NVARCHAR(255)) AS driver_name,
    CAST('Unknown' AS NVARCHAR(50)) AS gender,
    CAST(NULL AS DATETIME2) AS hire_date,
    CAST(NULL AS INT) AS experience_years,
    CAST('Unknown' AS NVARCHAR(50)) AS license_class,
    CAST('Unknown' AS NVARCHAR(100)) AS home_city,
    CAST(NULL AS DECIMAL(5, 2)) AS safety_score