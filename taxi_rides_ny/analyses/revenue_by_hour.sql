/*
    ANALYSIS: Revenue by Hour of Day
    
    Purpose: Analyze which hours generate the most revenue
    
    This is NOT a model - it won't create a table/view
    Use this for: Ad-hoc analysis, reports, Jupyter notebooks
    
    Run with: dbt compile (generates SQL in target/compiled/analyses/)
    Then copy SQL to BigQuery console or BI tool
*/

SELECT
    pickup_hour,
    service_type,
    COUNT(*) AS trip_count,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_fare,
    ROUND(AVG(trip_distance), 2) AS avg_distance
FROM {{ ref('fact_trips') }}
WHERE pickup_datetime >= '2019-01-01'
GROUP BY 1, 2
ORDER BY total_revenue DESC
LIMIT 20
