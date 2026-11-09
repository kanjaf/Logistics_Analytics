-- Test: assert_fct_fuel_transactions_vehicle_consistency
-- Purpose: Identify conflicting vehicle assignments.
-- Missing trip vehicle assignments are preserved and excluded
-- from this consistency comparison.

SELECT
    fuel_transaction_id,
    trip_id,
    vehicle_id AS fuel_transaction_vehicle_id,
    trip_vehicle_id
FROM {{ ref('fct_fuel_transactions') }}
WHERE trip_vehicle_id IS NOT NULL
  AND vehicle_id <> trip_vehicle_id