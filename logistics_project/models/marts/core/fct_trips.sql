
-- Model: fct_trips
-- Grain: One row per trip.
-- Purpose: Provide trip-level operational KPIs for Power BI.

WITH shipment_links AS (
    SELECT
        trip_id,
        COUNT(*) AS shipment_count
    FROM {{ ref('stg_shipments') }}
    WHERE trip_id IS NOT NULL
    GROUP BY trip_id
)

SELECT
    t.trip_id,
    t.route_id,
    t.vehicle_id,
    t.driver_id,

    CAST(t.planned_departure AS DATE) AS trip_date,

    t.planned_departure,
    t.actual_departure,
    t.planned_arrival,
    t.actual_arrival,

    t.planned_distance_km,
    t.actual_distance_km,
    t.trip_status,

    CASE
        WHEN t.trip_status = 'Completed' THEN 1
        ELSE 0
    END AS is_completed,

    t.missing_vehicle_id_flag,
    t.missing_driver_id_flag,
    t.missing_actual_departure_flag,
    t.missing_actual_arrival_flag,

    COALESCE(s.shipment_count, 0) AS shipment_count,

    CASE
        WHEN s.trip_id IS NULL THEN 1
        ELSE 0
    END AS no_shipment_link_flag,

    CASE
        WHEN t.trip_status <> 'Completed' THEN NULL
        WHEN t.actual_departure IS NULL
          OR t.actual_arrival IS NULL THEN NULL
        ELSE DATEDIFF(
            MINUTE,
            t.actual_departure,
            t.actual_arrival
        )
    END AS actual_duration_minutes,

    CASE
        WHEN t.trip_status <> 'Completed' THEN NULL
        WHEN t.actual_arrival IS NULL
          OR t.planned_arrival IS NULL THEN NULL
        ELSE DATEDIFF(
            MINUTE,
            t.planned_arrival,
            t.actual_arrival
        )
    END AS arrival_variance_minutes,

    CASE
        WHEN t.trip_status <> 'Completed' THEN NULL
        WHEN t.actual_arrival IS NULL
          OR t.planned_arrival IS NULL THEN NULL
        WHEN t.actual_arrival >
             DATEADD(
                 MINUTE,
                 {{ var('late_grace_minutes', 0) }},
                 t.planned_arrival
             )
        THEN 1
        ELSE 0
    END AS late_arrival_flag,

    CASE
        WHEN t.planned_distance_km IS NULL
          OR t.actual_distance_km IS NULL THEN NULL
        ELSE t.actual_distance_km - t.planned_distance_km
    END AS distance_variance_km

FROM {{ ref('stg_trips') }} AS t

LEFT JOIN shipment_links AS s
    ON t.trip_id = s.trip_id
