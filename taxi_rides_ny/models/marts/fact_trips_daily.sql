/*
    MART MODEL: fact_trips_daily
    
    Purpose: Daily aggregated trip statistics
    
    This model demonstrates:
    1. Using custom macros
    2. GROUP BY aggregations
    3. Date truncation
*/

WITH daily_trips AS (
    SELECT
        DATE(pickup_datetime) AS trip_date,
        service_type,
        
        -- Use our custom macro to make payment type readable
        {{ get_payment_type_description('payment_type') }} AS payment_method,
        
        -- Aggregations
        COUNT(*) AS trip_count,
        SUM(passenger_count) AS total_passengers,
        ROUND(AVG(trip_distance), 2) AS avg_trip_distance,
        ROUND(AVG(trip_duration_minutes), 2) AS avg_trip_duration,
        SUM(total_amount) AS total_revenue,
        ROUND(AVG(total_amount), 2) AS avg_fare,
        
        -- Use safe_divide macro to calculate revenue per mile (avoids division by zero)
        {{ safe_divide('SUM(total_amount)', 'SUM(trip_distance)', 2) }} AS avg_revenue_per_mile
        
    FROM {{ ref('fact_trips') }}
    WHERE pickup_datetime IS NOT NULL
    GROUP BY 1, 2, 3
)

SELECT * FROM daily_trips
ORDER BY trip_date DESC, service_type
