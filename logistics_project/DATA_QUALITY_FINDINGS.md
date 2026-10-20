# Logistics Analytics — Data Quality Findings

## 1. Overview

This document records data-quality issues identified while developing the dbt staging model for shipment data in the `Logistics_Analytics` SQL Server database.

The purpose of this investigation is to assess the reliability of shipment records before using them for delivery-performance reporting and downstream analytics.

**Model:** `stg_shipments`  
**Source:** `raw_logistics.shipments`  
**Warehouse platform:** Microsoft SQL Server  
**Transformation tool:** dbt Core

## 2. Duplicate Shipment Records

The raw shipments table contained 12,040 rows. After applying `SELECT DISTINCT` in the staging model, the resulting `stg_shipments` model contained 12,000 rows.

This represents a reduction of 40 rows through deduplication.

**Treatment:** Exact duplicate records are removed in staging. The raw source data is preserved.

**Validation:** Compare raw and staged row counts and test shipment identifier uniqueness.

## 3. In-Transit Shipments With Actual Delivery Dates

A data-quality flag was introduced to identify records whose delivery status indicates that a shipment is in transit even though an actual delivery date is populated.

The flag normalizes status values by replacing underscores with spaces and comparing the result to `IN TRANSIT`, allowing it to identify both `In Transit` and `IN_TRANSIT`.

| Measure | Result |
|---|---:|
| Total staged shipments | 12,000 |
| Flagged shipments | 2,724 |
| Flagged share of staged shipments | 22.7% |

**Interpretation:** The status and actual delivery date fields conflict. An actual delivery date does not independently prove that the shipment was delivered, because the date itself could be incorrect.

**Treatment:** Preserve the original status and date. Flag the inconsistency for investigation rather than silently changing either field.

## 4. Delivery Delay Flag Inconsistencies

The source `is_delayed` field was compared with the expected and actual delivery timestamps.

For this investigation, a date-based delay is defined as:

`actual_delivery_date > expected_delivery_date`

The following inconsistencies were identified:

| Finding | Shipment count |
|---|---:|
| Actual delivery after expected date, but `is_delayed = 0` | 2,589 |
| `is_delayed = 1`, but actual delivery is not after expected date | 2 |
| **Total delay-flag mismatches** | **2,591** |

The total of 2,591 mismatches was verified using a SQL query against all 12,000 staged shipments.

**Mismatch rate:** Approximately 21.6% of staged shipments.

**Treatment:** Introduce a `delay_flag_mismatch` field to identify disagreements between the source delay flag and the date-based comparison. Preserve the original `is_delayed` value.

**Important limitation:** The date-based comparison assumes that the expected and actual timestamps are reliable. The mismatch flag identifies disagreement; it does not determine which source field is correct.

## 5. Delivery Status and Delay Flag Analysis

The following status-level patterns were observed:

| Delivery status | `is_delayed` | Actual after expected | Count |
|---|---:|---:|---:|
| Delivered | 0 | No | 5,957 |
| Delivered | 0 | Yes | 1,905 |
| Delivered Late | 1 | No | 2 |
| Delivered Late | 1 | Yes | 1,412 |
| In Transit | 0 | No | 1,989 |
| In Transit | 0 | Yes | 658 |
| IN_TRANSIT | 0 | No | 51 |
| IN_TRANSIT | 0 | Yes | 26 |

These results show that the delay-flag disagreement occurs across multiple delivery statuses. The `In Transit` records also exhibit a separate status-versus-date inconsistency.

## 6. Data Handling Principles

The staging process follows these principles:

1. Preserve original source values unless a correction can be justified.
2. Use explicit flags to make identified data-quality issues visible.
3. Distinguish source-system fields from calculated analytical fields.
4. Validate transformation results with SQL queries and dbt tests.
5. Document assumptions and limitations before calculating business KPIs.

## 7. Outstanding Work

- Verify the successful build and counts for `delay_flag_mismatch`.
- Add dbt tests and descriptions for the new data-quality fields.
- Investigate other staging tables for nulls, duplicates, invalid values and inconsistent relationships.
- Assess timestamp and delay-day consistency.
- Define documented business rules for downstream delivery-performance metrics.
- Decide how flagged records should be treated in analytical models without concealing source-data problems.

## 8. Current Conclusion

The shipment dataset contains measurable inconsistencies between delivery status, expected and actual delivery timestamps, and the source delay indicator.

These issues are being documented and exposed through staging-level quality flags. No unsupported corrections have been applied to the source fields.
