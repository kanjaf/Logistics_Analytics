
-- Model: stg_customs
-- Purpose: Clean and standardize customs clearance records.
--
-- Data-quality decisions:
-- 1. Preserve the original duty_rate TIME value for traceability.
-- 2. Calculate a separate duty rate from duty_amount / declared_value.
-- 3. Round the calculated percentage to two decimal places.
-- 4. Preserve missing financial values and return NULL when the
--    calculated rate cannot be determined.
-- 5. Standardize customs statuses to lowercase.
-- 6. Preserve source records rather than inventing replacements.

WITH source_data AS (
    SELECT
        customs_id,
        shipment_id,
        declaration_date,
        customs_status,
        declared_value,
        duty_rate,
        duty_amount,
        clearance_days,
        inspection_required
    FROM {{ source('raw_logistics', 'customs') }}
),

cleaned AS (
    SELECT
        NULLIF(LTRIM(RTRIM(customs_id)), '') AS customs_id,

        NULLIF(LTRIM(RTRIM(shipment_id)), '') AS shipment_id,

        declaration_date,

        CASE
            WHEN customs_status IS NULL
                OR LTRIM(RTRIM(customs_status)) = ''
                THEN NULL
            ELSE LOWER(LTRIM(RTRIM(customs_status)))
        END AS customs_status,

        CAST(declared_value AS DECIMAL(18, 2)) AS declared_value,

        duty_rate AS source_duty_rate,

        CAST(duty_amount AS DECIMAL(18, 2)) AS duty_amount,

        CAST(clearance_days AS DECIMAL(8, 2)) AS clearance_days,

        inspection_required

    FROM source_data
)

SELECT
    *,

    CAST(
        ROUND(
            100.0 * duty_amount / NULLIF(declared_value, 0),
            2
        ) AS DECIMAL(8, 2)
    ) AS calculated_duty_rate_pct

FROM cleaned;
