{{ config(materialized='view') }}

-- Model: dim_warehouse
-- Grain: One row per warehouse, including one UNKNOWN member.
-- Purpose: Warehouse attributes for geographic, capacity,
-- and operating cost analysis.

SELECT
    warehouse_id,
    warehouse_name,
    city,
    country,
    warehouse_type,
    capacity_units,
    operating_cost_per_day
FROM {{ ref('stg_warehouses') }}

UNION ALL

SELECT
    CAST('UNKNOWN' AS NVARCHAR(50)) AS warehouse_id,
    CAST('Unknown' AS NVARCHAR(255)) AS warehouse_name,
    CAST('Unknown' AS NVARCHAR(100)) AS city,
    CAST('Unknown' AS NVARCHAR(100)) AS country,
    CAST('Unknown' AS NVARCHAR(100)) AS warehouse_type,
    CAST(NULL AS INT) AS capacity_units,
    CAST(NULL AS BIGINT) AS operating_cost_per_day