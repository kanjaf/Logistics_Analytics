
-- Model: stg_fuel_transactions
-- Purpose: Clean fuel transactions and flag data-quality issues.
--
-- Data-quality decisions:
-- 1. Preserve all source transactions and transaction IDs.
-- 2. Trim whitespace and uppercase text identifiers.
-- 3. Convert transaction_date to DATETIME2.
-- 4. Standardize fuel station names:
--    - Replace commas and hyphens with spaces.
--    - Convert names to uppercase.
--    - Convert blank names to NULL.
-- 5. Preserve zero and negative litres; flag non-positive values.
-- 6. Preserve recorded fuel_cost; flag differences greater than 1.00.
-- 7. Use absolute litres for cost reconciliation only.
-- 8. Preserve missing fuel_station values as NULL.

WITH source_data AS (
    SELECT
        fuel_transaction_id,
        trip_id,
        vehicle_id,
        transaction_date,
        litres,
        price_per_litre,
        fuel_cost,
        fuel_station
    FROM {{ source('raw_logistics', 'fuel_transactions') }}
),

cleaned AS (
    SELECT
        UPPER(
            NULLIF(LTRIM(RTRIM(fuel_transaction_id)), '')
        ) AS fuel_transaction_id,

        UPPER(
            NULLIF(LTRIM(RTRIM(trip_id)), '')
        ) AS trip_id,

        UPPER(
            NULLIF(LTRIM(RTRIM(vehicle_id)), '')
        ) AS vehicle_id,

        TRY_CONVERT(
            DATETIME2,
            NULLIF(LTRIM(RTRIM(transaction_date)), '')
        ) AS transaction_date,

        CAST(litres AS DECIMAL(10, 2)) AS litres,

        CAST(price_per_litre AS DECIMAL(10, 2))
            AS price_per_litre,

        CAST(fuel_cost AS DECIMAL(12, 2)) AS fuel_cost,

        UPPER(
            NULLIF(
                LTRIM(
                    RTRIM(
                        REPLACE(
                            REPLACE(fuel_station, ',', ' '),
                            '-', ' '
                        )
                    )
                ),
                ''
            )
        ) AS fuel_station,

        -- Retain raw numeric values for accurate quality checks.
        litres AS source_litres,
        price_per_litre AS source_price_per_litre,
        fuel_cost AS source_fuel_cost

    FROM source_data
),

flagged AS (
    SELECT
        fuel_transaction_id,
        trip_id,
        vehicle_id,
        transaction_date,
        litres,
        price_per_litre,
        fuel_cost,
        fuel_station,

        CASE
            WHEN source_litres <= 0 THEN 1
            ELSE 0
        END AS nonpositive_litres_flag,

        CASE
            WHEN ABS(
                source_fuel_cost
                - (ABS(source_litres) * source_price_per_litre)
            ) > 1.00 THEN 1
            ELSE 0
        END AS fuel_cost_mismatch_flag

    FROM cleaned
)

SELECT *
FROM flagged;
