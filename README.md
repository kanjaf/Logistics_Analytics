# Logistics Analytics | End-to-End Data Pipeline & Business Intelligence

## Project Overview

This project develops an end-to-end logistics analytics solution to transform raw shipment and operational data into actionable business insights.

The project simulates a freight and logistics environment, focusing on shipment performance, delivery reliability, transportation costs, operational efficiency, and customer service.

The objective is to demonstrate practical skills in SQL, data transformation, analytics engineering, data quality, and Power BI reporting.

## Business Objectives

- Monitor on-time delivery performance and shipment delays.
- Identify routes, warehouses, and operational factors associated with delays.
- Analyse shipping costs and transportation efficiency.
- Track shipment volumes and delivery performance over time.
- Assess data quality and improve the reliability of reporting.
- Build a reusable data pipeline that supports consistent business reporting.

## Technology Stack

| Technology | Purpose |
|---|---|
| SQL Server | Raw data storage and SQL-based data exploration |
| SQL | Data profiling, cleaning, validation, and transformation |
| Python | Supporting data preparation and automation where required |
| dbt | Modular, documented, and testable data transformations |
| Power BI | Interactive dashboards and business intelligence |
| Git & GitHub | Version control and project documentation |

## Project Architecture

Raw CSV Files → SQL Server → SQL Transformations → dbt Models → Power BI Dashboard

## Dataset

The project uses synthetic logistics data designed to represent a freight operations environment.

Planned data domains include:

- Shipments
- Shipment tracking events
- Trips and transportation costs
- Warehouses
- Vehicles
- Drivers
- Customers
- Routes
- Customs and shipment clearance

The data is intended to support realistic data-quality checks, operational analysis, and business reporting.

## Data Engineering & Analytics Workflow

1. **Data ingestion:** Load source CSV files into SQL Server.
2. **Data profiling:** Inspect schemas, data types, missing values, duplicates, and inconsistencies.
3. **Data quality:** Identify and document data issues before transformation.
4. **SQL transformation:** Clean and standardise source data.
5. **Analytics engineering:** Develop modular dbt models and introduce data tests.
6. **Business metrics:** Define reliable shipment, delivery, and cost KPIs.
7. **Visualisation:** Develop Power BI dashboards for operational decision-making.
8. **Documentation:** Maintain project documentation, model descriptions, and validation results.

## Key Performance Indicators

Planned metrics include:

- On-time delivery rate
- Average delivery time
- Average shipment delay
- Shipment volume and delivery status
- Transportation cost per shipment
- Cost per kilometre, where the required data is available
- Delay rates by route and warehouse
- Shipment exceptions and tracking-event completeness

Final KPI definitions will be documented alongside the implemented models and dashboard.

## Data Quality & Testing

The project will address issues such as:

- Exact duplicate shipment records
- Missing or invalid values
- Inconsistent data types
- Invalid status values
- Referential integrity between related datasets
- Duplicate business keys and inconsistent event timestamps

dbt tests will be used where appropriate to validate transformed models.

## Project Status

**Status:** In development

Current focus:
- Source data loaded into SQL Server
- Initial data profiling and duplicate investigation
- dbt project setup and SQL Server connectivity
- Development of the transformation layer

Upcoming milestones:
- Complete source data quality checks
- Build and test dbt staging models
- Develop business-ready analytical models
- Create the Power BI dashboard
- Document insights and project findings

## Repository Structure

The repository will evolve as the project develops. The intended structure includes:

```text
logisticsAnalytics/
├── README.md
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── tests/
├── analyses/
├── macros/
└── dbt_project.yml
```

## Expected Outcome

A documented, testable logistics analytics pipeline and Power BI reporting solution that demonstrates the application of data engineering and business intelligence techniques to freight operations.

*Note: This is a portfolio project using synthetic data. Findings and business recommendations will be added after the transformations and analysis are complete.*