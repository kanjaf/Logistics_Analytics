# Logistics Analytics

A portfolio project demonstrating data transformation and analytics for logistics and freight operations.

## Technology Stack
- Microsoft SQL Server
- dbt Core and dbt-sqlserver
- SQL
- Power BI (planned reporting layer)

## Current Progress
- Connected dbt to a local SQL Server logistics database.
- Registered 14 raw logistics tables as dbt sources.
- Built a shipment staging model.
- Trimmed text fields, handled blanks, cast numeric data types, and removed duplicate transformed records.
- Added not-null and uniqueness tests for shipment identifiers.

## Roadmap
1. Build the remaining staging models.
2. Develop intermediate transformations and analytical marts.
3. Create logistics KPIs and a Power BI dashboard.
4. Document business insights and recommendations.

## Running the Project
Configure a local dbt profile, then run:

    dbt debug --project-dir logistics_project
    dbt run --project-dir logistics_project
    dbt test --project-dir logistics_project

Keep database credentials and local configuration out of version control.
