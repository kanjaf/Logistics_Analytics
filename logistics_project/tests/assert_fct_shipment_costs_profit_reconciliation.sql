-- Test: assert_fct_shipment_costs_profit_reconciliation
-- Purpose: Ensure calculated_gross_profit equals revenue minus
-- total_cost whenever revenue and total_cost are available.

SELECT
    cost_id,
    revenue,
    total_cost,
    calculated_gross_profit

FROM {{ ref('fct_shipment_costs') }}

WHERE
    revenue IS NOT NULL
    AND total_cost IS NOT NULL
    AND (
        calculated_gross_profit IS NULL
        OR ABS(
            calculated_gross_profit - (revenue - total_cost)
        ) > 0.01
    )