WITH source_data AS (
    SELECT *
    FROM {{ source('raw_logistics', 'shipments') }}
),

cleaned AS (
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(shipment_id)), '') AS shipment_id,
        NULLIF(LTRIM(RTRIM(customer_id)), '') AS customer_id,
        NULLIF(LTRIM(RTRIM(trip_id)), '') AS trip_id,
        NULLIF(LTRIM(RTRIM(route_id)), '') AS route_id,
        booking_date,
        NULLIF(LTRIM(RTRIM(shipment_type)), '') AS shipment_type,
        NULLIF(LTRIM(RTRIM(priority)), '') AS priority,
        NULLIF(LTRIM(RTRIM(origin)), '') AS origin,
        NULLIF(LTRIM(RTRIM(destination)), '') AS destination,
        CAST(weight_kg AS DECIMAL(12, 2)) AS weight_kg,
        CAST(volume_m3 AS DECIMAL(12, 3)) AS volume_m3,
        CAST(shipment_value AS DECIMAL(18, 2)) AS shipment_value,
        expected_delivery_date,
        actual_delivery_date,
        NULLIF(LTRIM(RTRIM(delivery_status)), '') AS delivery_status,
        is_delayed,
        CAST(delay_days AS INT) AS delay_days
    FROM source_data
)

SELECT *
FROM cleaned
