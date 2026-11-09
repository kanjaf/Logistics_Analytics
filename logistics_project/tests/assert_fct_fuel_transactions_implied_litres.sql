
-- Test: assert_fct_fuel_transactions_implied_litres
-- Purpose: Validate implied litres against recorded fuel cost
-- and price per litre.

SELECT
    fuel_transaction_id,
    fuel_cost,
    price_per_litre,
    implied_litres,
    CAST(
        fuel_cost / NULLIF(price_per_litre, 0)
        AS DECIMAL(12, 4)
    ) AS expected_implied_litres
FROM {{ ref('fct_fuel_transactions') }}
WHERE price_per_litre <= 0
   OR fuel_cost <= 0
   OR ABS(
        implied_litres -
        (fuel_cost / NULLIF(price_per_litre, 0))
   ) > 0.0001
   OR implied_litres IS NULL
