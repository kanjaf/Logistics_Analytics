
{{ config(materialized='view') }}

-- Model: fct_shipment_costs
-- Grain: One row per shipment cost record.
-- Purpose: Supports shipment cost, revenue and profitability analysis.
--
-- Data-quality decisions:
-- 1. Preserve all 12,000 shipment cost records.
-- 2. Preserve original cost components and financial measures.
-- 3. Preserve NULL cost components and revenue values.
-- 4. Preserve recorded total_cost and gross_profit.
-- 5. Retain calculated_total_cost from staging.
-- 6. Derive calculated_gross_profit only when revenue is available.
-- 7. Preserve all staging data-quality flags.
-- 8. Link each cost record to its shipment.

SELECT
    c.cost_id,
    c.shipment_id,

    c.transport_cost,
    c.fuel_cost,
    c.handling_cost,
    c.warehouse_cost,
    c.customs_cost,

    c.total_cost,
    c.calculated_total_cost,

    c.revenue,
    c.gross_profit,

    CASE
        WHEN c.revenue IS NOT NULL
         AND c.total_cost IS NOT NULL
        THEN c.revenue - c.total_cost
        ELSE NULL
    END AS calculated_gross_profit,

    c.missing_transport_cost_flag,
    c.missing_fuel_cost_flag,
    c.total_cost_mismatch_flag,
    c.gross_profit_mismatch_flag

FROM {{ ref('stg_shipment_costs') }} AS c

INNER JOIN {{ ref('fct_shipments') }} AS s
    ON c.shipment_id = s.shipment_id
