/*
    MART MODEL: fct_monthly_zone_revenue
    
    Purpose: Monthly revenue aggregation per pickup zone and service type
    
    What this model does:
    1. Groups trip data by month, pickup zone, and service type
    2. Calculates revenue metrics (total amount, fares, surcharges, etc.)
    3. Counts trips and calculates averages
    4. This is the model required for homework Questions 3-5!
*/

WITH trips_with_revenue AS (
    SELECT 
        service_type,
        pickup_location_id,
        DATE_TRUNC(DATE(pickup_datetime), MONTH) AS revenue_month,
        
        -- Revenue amounts
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount,
        congestion_surcharge,
        
        -- Trip metrics
        passenger_count,
        trip_distance
        
    FROM {{ ref('fact_trips') }}
)

SELECT 
    -- Grouping dimensions
    revenue_month,
    service_type,
    pickup_location_id AS revenue_zone,
    
    -- Revenue calculations
    SUM(fare_amount) AS revenue_monthly_fare,
    SUM(extra) AS revenue_monthly_extra,
    SUM(mta_tax) AS revenue_monthly_mta_tax,
    SUM(tip_amount) AS revenue_monthly_tip_amount,
    SUM(tolls_amount) AS revenue_monthly_tolls_amount,
    SUM(improvement_surcharge) AS revenue_monthly_improvement_surcharge,
    SUM(total_amount) AS revenue_monthly_total_amount,
    SUM(congestion_surcharge) AS revenue_monthly_congestion_surcharge,
    
    -- Trip counts and averages
    COUNT(*) AS total_monthly_trips,
    AVG(passenger_count) AS avg_monthly_passenger_count,
    AVG(trip_distance) AS avg_monthly_trip_distance

FROM trips_with_revenue
GROUP BY 1, 2, 3
