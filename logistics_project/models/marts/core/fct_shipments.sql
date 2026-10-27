
-- Model: fct_shipments
-- Grain: One row per shipment.
-- Purpose: Shipment delivery performance, financial metrics,
--          and data-quality flags for Power BI.

SELECT
    s.shipment_id,

    -- Preserve the original customer ID for data-quality tracing.
    s.customer_id AS source_customer_id,

    -- Map missing and unresolved customer references to Unknown.
    CASE
        WHEN s.customer_id IS NULL
          OR s.customer_id = 'CUST99999'
            THEN 'UNKNOWN'
        ELSE s.customer_id
    END AS customer_id,

    s.trip_id,
    s.route_id,

    s.booking_date,
    s.expected_delivery_date,
    s.actual_delivery_date,

    s.shipment_type,
    s.priority,
    s.origin,
    s.destination,
    s.delivery_status,

    s.weight_kg,
    s.volume_m3,
    s.shipment_value,

    s.is_delayed,
    s.delay_days,
    s.delay_flag_mismatch,
    s.in_transit_with_actual_date_flag,

    c.cost_id,
    c.transport_cost,
    c.fuel_cost,
    c.handling_cost,
    c.warehouse_cost,
    c.customs_cost,
    c.total_cost,
    c.revenue,
    c.gross_profit,

    c.missing_transport_cost_flag,
    c.missing_fuel_cost_flag,
    c.total_cost_mismatch_flag,
    c.gross_profit_mismatch_flag,

    CASE
        WHEN s.actual_delivery_date IS NULL THEN NULL
        WHEN s.expected_delivery_date IS NULL THEN NULL
        WHEN s.actual_delivery_date > s.expected_delivery_date THEN 1
        ELSE 0
    END AS late_delivery_flag,

    CASE
        WHEN s.actual_delivery_date IS NULL
          OR s.expected_delivery_date IS NULL THEN NULL
        ELSE DATEDIFF(
            DAY,
            s.expected_delivery_date,
            s.actual_delivery_date
        )
    END AS delivery_variance_days,

    CASE
        WHEN c.revenue IS NULL OR c.total_cost IS NULL THEN NULL
        ELSE c.revenue - c.total_cost
    END AS calculated_profit,

    CASE
        WHEN c.total_cost IS NULL OR c.total_cost = 0 THEN NULL
        WHEN c.revenue IS NULL THEN NULL
        ELSE c.revenue / NULLIF(c.total_cost, 0)
    END AS revenue_to_cost_ratio

FROM {{ ref('stg_shipments') }} AS s

LEFT JOIN {{ ref('stg_shipment_costs') }} AS c
    ON s.shipment_id = c.shipment_id
