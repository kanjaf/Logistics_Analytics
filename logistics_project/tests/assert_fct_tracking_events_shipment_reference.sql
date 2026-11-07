-- Test: assert_fct_tracking_events_shipment_reference
-- Purpose: Verify shipment reference classifications against source data.

SELECT
    f.tracking_event_id,
    f.shipment_id,
    f.shipment_reference_status
FROM {{ ref('fct_tracking_events') }} AS f

LEFT JOIN {{ ref('fct_shipments') }} AS s
    ON f.shipment_id = s.shipment_id

WHERE
       (f.shipment_id IS NULL
        AND f.shipment_reference_status <> 'MISSING')

    OR (f.shipment_id IS NOT NULL
        AND s.shipment_id IS NULL
        AND f.shipment_reference_status <> 'UNMATCHED')

    OR (s.shipment_id IS NOT NULL
        AND f.shipment_reference_status <> 'MATCHED')