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

## 9. Driver Data Quality Findings

**Source table:** `dbo.drivers`  
**Staging model:** `stg_drivers`

### Source profile

The drivers table contains 240 records. No duplicate driver IDs or missing driver IDs were identified. All driver names were populated.

| Check | Result |
|---|---:|
| Source driver records | 240 |
| Staged driver records | 240 |
| Distinct driver IDs | 240 |
| Missing driver IDs | 0 |
| Missing driver names | 0 |
| Missing safety scores | 5 |
| Observed minimum safety score | 47.80 |
| Observed maximum safety score | 100.00 |

### Missing safety scores

Five drivers have a `NULL` value in `safety_score`. Their other displayed attributes were populated.

**Treatment:** Missing scores are preserved as `NULL`. No score is imputed because the source data does not establish why the values are missing or what the correct scores should be.

### Numeric precision

The source `safety_score` column uses a floating-point data type, producing values such as `47.7999992370605`. The staging model rounds scores to two decimal places and casts them to `DECIMAL(5,2)` for consistent reporting.

The observed score range is descriptive only. A formal business rule defining valid safety-score boundaries has not yet been confirmed.

### Other observations

- The source contains 125 records with gender recorded as `Male` and 115 as `Female`.
- Three licence classes were observed: `B`, `C`, and `CE`.
- Hire dates ranged from January 2015 to December 2024.
- Experience ranged from 1 to 11 years.
- No future hire dates or experience values above 60 years were identified in the screening checks.

These findings do not establish the correctness of every source value; they record the checks performed and their results.

### dbt validation

The `stg_drivers` model built successfully. Three configured tests passed:

- `driver_id` is not null.
- `driver_id` is unique.
- `driver_name` is not null.

The missing safety scores are intentionally retained and are not currently tested as non-null.
## Route Data Quality Findings

### Negative route distances

**Finding:** Four of the 90 routes have a recorded distance of -100 km.

**Affected route IDs:**
- ROUTE0005
- ROUTE0015
- ROUTE0067
- ROUTE0078

**Impact:** Negative distances are invalid for route-distance analysis and may distort distance-based reporting, transportation cost analysis, and route efficiency metrics.

**Handling decision:**
- Preserve the original `distance_km` values in the staging model.
- Create `invalid_distance_flag`, set to 1 when `distance_km <= 0`, otherwise 0.
- Do not replace negative distances with zero or estimated values without a verified source.
- Exclude or investigate flagged records before using route distances in analytical metrics.

**Validation:** The staging model contains 90 routes, including four records flagged for non-positive distances. The flag matches the source values.

**Recommended follow-up:** Verify the four distances against an authoritative route-distance source before using these records for distance-based analysis.

## Customs Data Quality Findings

### 1. Duty Rate Stored as an Incorrect Data Type

**Issue:** The source `dbo.customs` table stores `duty_rate` as SQL Server `TIME`, even though the field represents a percentage. This makes the source column unsuitable for direct percentage calculations and reporting.

**Investigation findings:**
- Total customs records: 12,000.
- The source duty-rate values include `00:01:00`, `00:02:00`, `00:05:00`, `00:15:00`, `00:25:00`, and `01:05:00`.
- The implied rate was calculated as `duty_amount / declared_value * 100`.
- The first five time values correspond consistently to implied rates of 10%, 20%, 5%, 15%, and 25%, respectively, across records where both financial amounts are available.
- Eight records contain the anomalous source value `01:05:00`. Their implied rates vary: three records at 5%, one at 10%, one at 20%, and three at 25%. Therefore, the intended percentage cannot be reliably inferred from this source value alone.

**Transformation decision:** The staging model preserves the original source value in `source_duty_rate` and introduces `calculated_duty_rate_pct`, derived from `duty_amount / declared_value * 100` and rounded to two decimal places. Missing financial values are preserved, and the calculated rate remains NULL when it cannot be determined.

**Validation results:**
- Total records: 12,000.
- Records with both declared value and duty amount available: 11,755.
- Records with uncalculable rates due to missing financial values: 245.
- Missing declared values: 240.
- Missing duty amounts: 5.
- Zero declared values: 0.

**Limitation:** The calculated percentage represents the rate implied by the available financial amounts. It does not independently establish that the declared value or duty amount is correct. The original source-rate field is retained for traceability, and the eight anomalous records are not silently corrected.

**Recommended upstream fix:** Change the source system's duty-rate field to a suitable numeric type, such as `DECIMAL`, and validate the rate against the duty amount and declared value at ingestion.
## Fuel Transactions (`dbo.fuel_transactions`)

### 1. Dataset Overview

The raw fuel transactions table contains **8,000 records** covering transactions from 1 January 2025 to 28 September 2026.

Profiling found no missing transaction IDs, trip IDs, vehicle IDs, transaction dates, litres, prices per litre, or recorded fuel costs. There were no duplicate transaction IDs or exact duplicate records. However, 240 records have missing fuel station names.

### 2. Non-Positive Fuel Quantities

Profiling identified **18 transactions with non-positive fuel quantities**:

| Issue | Records | Finding |
|---|---:|---|
| Negative litres | 8 | All eight records have a quantity of -100 litres |
| Zero litres | 10 | All ten records have zero litres |
| Total | 18 | All 18 have positive recorded fuel costs |

These records require investigation because zero or negative quantities do not reconcile naturally with positive recorded fuel costs. Negative quantities could represent reversals or corrections, but the source data does not establish their meaning.

**Decision:** Preserve the original quantities and recorded costs. The `stg_fuel_transactions` model adds `nonpositive_litres_flag`, set to 1 when the original quantity is zero or negative, and 0 otherwise. The model does not silently correct or remove these records.

### 3. Recorded Fuel Cost Does Not Reconcile with Calculated Cost

Fuel costs were checked against the following calculation:

`ABS(litres) × price_per_litre`

A tolerance of 1.00 was used to account for minor rounding differences. Absolute litres were used for this diagnostic comparison so that negative quantities could also be assessed; this does not imply that negative quantities are valid fuel purchases.

| Reconciliation result | Transactions | Percentage |
|---|---:|---:|
| Match within 1.00 | 5,584 | 69.80% |
| Difference greater than 1.00 | 2,416 | 30.20% |
| Total assessed | 8,000 | 100.00% |

Further analysis separated the results by quantity:

| Quantity category | Transactions | Matching costs | Mismatching costs |
|---|---:|---:|---:|
| Positive litres | 7,982 | 5,584 | 2,398 |
| Zero litres | 10 | 0 | 10 |
| Negative litres | 8 | 0 | 8 |
| Total | 8,000 | 5,584 | 2,416 |

The discrepancy is not limited to zero and negative quantities. Among the 7,982 transactions with positive quantities, **2,398 (approximately 30.07%)** still differ from the calculated cost by more than 1.00.

**Decision:** Preserve `fuel_cost` as recorded in the source. The `stg_fuel_transactions` model adds `fuel_cost_mismatch_flag`, set to 1 when the absolute difference between recorded cost and calculated cost exceeds 1.00, and 0 otherwise. The flag uses the original numeric values before reporting precision is applied. No recorded costs are overwritten.

The tolerance is a diagnostic choice for this project, not a confirmed business rule. The reasons for the discrepancies remain unverified and should be investigated with the data owner before any source values are corrected.

### 4. Fuel Station Standardization

A total of 240 records have missing fuel station names. These values are retained as `NULL`.

For non-missing station names, the staging model trims surrounding whitespace, converts text to uppercase, and replaces commas and hyphens with spaces. This improves consistency when grouping fuel transactions by station. It does not establish whether differently written names refer to the same real-world station.

### 5. Staging Decisions and Outstanding Questions

- Preserve all 8,000 source transactions.
- Retain negative and zero quantities and expose them through `nonpositive_litres_flag`.
- Retain recorded fuel costs and expose discrepancies through `fuel_cost_mismatch_flag`.
- Preserve missing station names as `NULL`.
- Investigate the business meaning of negative quantities, zero-quantity transactions with positive costs, and the 2,416 cost discrepancies.
- Confirm the expected treatment of rounding, reversals, adjustments, and other fuel-cost components with the data owner before changing any source values.
### Route Scope Classification

**Objective:** Derive a consistent route classification from the origin and destination countries instead of relying solely on the source `route_type` field.

**Methodology:**
- Map `origin_city` and `destination_city` to countries using `african_countries_cities`.
- Exclude city names from the mapping when they correspond to more than one country, avoiding ambiguous country assignments.
- Assign `INLAND` when the origin and destination countries are the same.
- Assign `CROSS BORDER` when the origin and destination countries differ.
- Leave `route_scope` as NULL if either city lacks an unambiguous country mapping.
- Preserve the source `route_type` after text standardization for comparison and auditability.

**Validation results:**

| Check | Result |
|---|---:|
| Total staged routes | 90 |
| INLAND routes | 23 |
| CROSS BORDER routes | 67 |
| Routes needing country-mapping review | 0 |
| Routes with invalid distances | 4 |

**Interpretation:** All 90 routes received a country-based classification using the current geography mapping. The resulting classification is independent of the original source `route_type`, which is retained for comparison.

**Limitations:**
- The classification depends on the accuracy of the geography reference data and the city-to-country mapping.
- `route_scope` describes whether a route crosses a national boundary; it does not independently verify the actual road travelled or the presence of a physical border crossing.
- The four routes with negative distances remain flagged for investigation. Their distance values have not been corrected.

**Treatment:** Use `route_scope` for consistent inland-versus-cross-border analysis while retaining the original `route_type` and `border_crossing` fields for traceability.
