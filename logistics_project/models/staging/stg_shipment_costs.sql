
-- Model: stg_shipment_costs
-- Purpose: Clean shipment cost records and flag financial data-quality issues.
--
-- Data-quality decisions:
-- 1. Preserve all source records and recorded financial values.
-- 2. Standardize identifiers by trimming whitespace and uppercasing.
-- 3. Cast financial values to two decimal places.
-- 4. Preserve missing cost components as NULL.
-- 5. Flag missing transport and fuel costs.
-- 6. Flag total-cost mismatches only when all components are present.
-- 7. Flag gross-profit mismatches when revenue, total_cost,
--    and gross_profit are present.
-- 8. Do not replace recorded totals or profits with calculated values.

WITH source_data AS (
    SELECT
        cost_id,
        shipment_id,
        transport_cost,
        fuel_cost,
        handling_cost,
        warehouse_cost,
        customs_cost,
        total_cost,
        revenue,
        gross_profit
    FROM {{ source('raw_logistics', 'shipment_costs') }}
),

cleaned AS (
    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(cost_id)), '')) AS cost_id,
        UPPER(NULLIF(LTRIM(RTRIM(shipment_id)), '')) AS shipment_id,

        CAST(transport_cost AS DECIMAL(18, 2)) AS transport_cost,
        CAST(fuel_cost AS DECIMAL(18, 2)) AS fuel_cost,
        CAST(handling_cost AS DECIMAL(18, 2)) AS handling_cost,
        CAST(warehouse_cost AS DECIMAL(18, 2)) AS warehouse_cost,
        CAST(customs_cost AS DECIMAL(18, 2)) AS customs_cost,
        CAST(total_cost AS DECIMAL(18, 2)) AS total_cost,
        CAST(revenue AS DECIMAL(18, 2)) AS revenue,
        CAST(gross_profit AS DECIMAL(18, 2)) AS gross_profit

    FROM source_data
),

calculated AS (
    SELECT
        *,
        CASE
            WHEN transport_cost IS NOT NULL
             AND fuel_cost IS NOT NULL
             AND handling_cost IS NOT NULL
             AND warehouse_cost IS NOT NULL
             AND customs_cost IS NOT NULL
            THEN
                transport_cost
                + fuel_cost
                + handling_cost
                + warehouse_cost
                + customs_cost
            ELSE NULL
        END AS calculated_total_cost

    FROM cleaned
),

flagged AS (
    SELECT
        *,

        CASE
            WHEN transport_cost IS NULL THEN 1
            ELSE 0
        END AS missing_transport_cost_flag,

        CASE
            WHEN fuel_cost IS NULL THEN 1
            ELSE 0
        END AS missing_fuel_cost_flag,

        CASE
            WHEN calculated_total_cost IS NOT NULL
             AND total_cost IS NOT NULL
             AND ABS(total_cost - calculated_total_cost) > 1.00
            THEN 1
            ELSE 0
        END AS total_cost_mismatch_flag,

        CASE
            WHEN revenue IS NOT NULL
             AND total_cost IS NOT NULL
             AND gross_profit IS NOT NULL
             AND ABS(gross_profit - (revenue - total_cost)) > 1.00
            THEN 1
            ELSE 0
        END AS gross_profit_mismatch_flag

    FROM calculated
)

SELECT *
FROM flagged;
