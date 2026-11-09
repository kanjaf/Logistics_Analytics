-- Test: assert_fct_shipment_costs_row_count
-- Purpose: Ensure all staging shipment cost records are preserved.

SELECT
    (SELECT COUNT(*)
     FROM {{ ref('stg_shipment_costs') }}) AS staging_row_count,

    (SELECT COUNT(*)
     FROM {{ ref('fct_shipment_costs') }}) AS fact_row_count

WHERE
    (SELECT COUNT(*)
     FROM {{ ref('stg_shipment_costs') }})
    <>
    (SELECT COUNT(*)
     FROM {{ ref('fct_shipment_costs') }})