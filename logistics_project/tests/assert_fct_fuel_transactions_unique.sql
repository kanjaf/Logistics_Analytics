
-- Test: assert_fct_fuel_transactions_unique
-- Purpose: Ensure each fuel transaction ID appears only once.

SELECT
    fuel_transaction_id,
    COUNT(*) AS duplicate_count
FROM {{ ref('fct_fuel_transactions') }}
GROUP BY fuel_transaction_id
HAVING COUNT(*) > 1
