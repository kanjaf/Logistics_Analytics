-- Verify that every known customer has a positive credit limit.
-- Exclude the UNKNOWN dimension member.

SELECT
    customer_id,
    credit_limit
FROM {{ ref('dim_customer') }}
WHERE customer_id != 'UNKNOWN'
  AND credit_limit <= 0