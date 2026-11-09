
{{ config(materialized='view') }}

-- Model: fct_fuel_transactions
-- Grain: One row per fuel transaction.
-- Purpose: Supports fuel expenditure, consumption,
-- vehicle and trip-level fuel efficiency analysis.
--
-- Data-quality decisions:
-- 1. Preserve all 8,000 source transactions.
-- 2. Preserve recorded litres, including zero and negative values.
-- 3. Use recorded fuel_cost as the authoritative expenditure.
-- 4. Derive implied_litres from fuel_cost / price_per_litre.
-- 5. Preserve original staging quality flags.
-- 6. Link each transaction to its trip, vehicle and date.
-- 7. Preserve the original fuel station.

SELECT
    f.fuel_transaction_id,

    f.trip_id,
    t.vehicle_id AS trip_vehicle_id,
    f.vehicle_id,

    v.registration_number,

    CONVERT(
        INT,
        CONVERT(CHAR(8), f.transaction_date, 112)
    ) AS date_key,

    f.transaction_date,

    f.litres AS recorded_litres,

    CAST(
        f.fuel_cost / NULLIF(f.price_per_litre, 0)
        AS DECIMAL(12, 4)
    ) AS implied_litres,

    f.price_per_litre,
    f.fuel_cost,
    f.fuel_station,

    f.nonpositive_litres_flag,
    f.fuel_cost_mismatch_flag

FROM {{ ref('stg_fuel_transactions') }} AS f

INNER JOIN {{ ref('fct_trips') }} AS t
    ON f.trip_id = t.trip_id

INNER JOIN {{ ref('dim_vehicle') }} AS v
    ON f.vehicle_id = v.vehicle_id
