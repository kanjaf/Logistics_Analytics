
{{ config(materialized='view') }}

-- Model: fct_delivery_exceptions
-- Grain: One row per delivery exception.
-- Purpose: Supports analysis of exception frequency, severity,
-- resolution status and resolution time.
--
-- Data-quality decisions:
-- 1. Preserve all 1,339 source exceptions.
-- 2. Retain NULL severity values rather than inventing classifications.
-- 3. Preserve resolution hours as recorded.
-- 4. Retain OPEN exceptions without assuming their resolution is complete.
-- 5. Shipment references have been validated against fct_shipments.

SELECT
    exception_id,
    shipment_id,
    CAST(exception_date AS DATE) AS exception_date,
    exception_type,
    severity,
    resolution_status,
    resolution_hours

FROM {{ ref('stg_delivery_exceptions') }}
