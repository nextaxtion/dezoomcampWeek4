# STEP 2: Data Modeling Concepts
## Dimensional Modeling for Analytics

**Video**: [Introduction to data modeling](https://www.youtube.com/watch?v=uF76d5EmdtU)  
**Reading**: Course materials on dimensional modeling

---

## WHY DATA MODELING MATTERS

You learned in Step 1 that dbt transforms data. But HOW should you structure that data?

**Bad structure** = slow queries, confused analysts, hard to maintain  
**Good structure** = fast, intuitive, scalable

**Dimensional modeling** is the industry standard for analytics databases. It's optimized for:
- ✅ Query performance (fast aggregations)
- ✅ Business understanding (analysts can navigate easily)
- ✅ Flexibility (easy to add new dimensions)

---

## THE TWO BUILDING BLOCKS

### 1. **FACT TABLES** (The Measurements)

**What**: Tables that store **metrics** and **measurements** about business events  
**Think**: "Things that happened"

**Characteristics:**
- Contains **numeric measures** (revenue, quantity, distance, duration)
- Contains **foreign keys** to dimension tables
- Usually **many rows** (one per event/transaction)
- **Grain**: What does one row represent? (e.g., "one taxi trip")

**Example - Taxi Trips Fact Table:**
```sql
fct_trips
├─ trip_id (primary key)
├─ pickup_datetime
├─ dropoff_datetime
├─ passenger_count (MEASURE)
├─ trip_distance (MEASURE)
├─ fare_amount (MEASURE)
├─ tip_amount (MEASURE)
├─ total_amount (MEASURE)
├─ pickup_location_id (FK to dim_location)
├─ dropoff_location_id (FK to dim_location)
└─ payment_type_id (FK to dim_payment_type)
```

**Key Questions for Fact Tables:**
- What business process are you measuring?
- What is the grain? (1 row = 1 what?)
- What are the numeric measures?
- What dimensions describe the context?

---

### 2. **DIMENSION TABLES** (The Context)

**What**: Tables that store **descriptive attributes** about your business  
**Think**: "Who, what, where, when, why, how"

**Characteristics:**
- Contains **text descriptions** and **attributes**
- Usually **fewer rows** than fact tables
- **Denormalized** (flat structure, not 3NF)
- Supports filtering, grouping, and reporting

**Example - Location Dimension Table:**
```sql
dim_zones
├─ location_id (primary key)
├─ borough (Brooklyn, Manhattan, Queens...)
├─ zone (East Harlem, Financial District...)
├─ service_zone (Yellow Zone, Airport, etc.)
└─ zone_name_full (descriptive name)
```

**Example - Payment Type Dimension:**
```sql
dim_payment_type
├─ payment_type_id (primary key)
├─ payment_type_name (Credit Card, Cash, etc.)
└─ payment_type_description
```

**Example - Date Dimension (very common):**
```sql
dim_date
├─ date_id (primary key: 20260212)
├─ full_date (2026-02-12)
├─ day_of_week (Wednesday)
├─ week_of_year (7)
├─ month_name (February)
├─ quarter (Q1)
├─ year (2026)
├─ is_weekend (false)
└─ is_holiday (false)
```

**Why Date Dimensions?**  
Instead of doing `EXTRACT(MONTH FROM date)` everywhere, you join to a date dimension and get pre-calculated attributes.

---

## STAR SCHEMA (The Standard Pattern)

**Definition**: One fact table in the center, surrounded by dimension tables

```
      dim_zones
          ↓
dim_date → fct_trips → dim_payment_type
          ↓
      dim_passenger
```

**Visual for NYC Taxi Data:**
```
          ┌─────────────────┐
          │   dim_zones     │
          │  (locations)    │
          └────────┬────────┘
                   │
    ┌──────────────┼──────────────┐
    │              ↓              │
┌───┴────┐    ┌─────────┐    ┌───┴──────┐
│dim_date│←───│fct_trips│───→│dim_payment│
└────────┘    └─────────┘    └──────────┘
                   ↑
              ┌────┴─────┐
              │dim_vendor│
              └──────────┘
```

**Benefits:**
- ✅ Simple for analysts to understand
- ✅ Fast query performance
- ✅ Dimensions are reusable across multiple facts
- ✅ Easy to add new dimensions

**Query Example:**
```sql
SELECT 
    d.month_name,
    z.borough,
    SUM(f.total_amount) as total_revenue,
    AVG(f.trip_distance) as avg_distance
FROM fct_trips f
JOIN dim_date d ON f.pickup_date_id = d.date_id
JOIN dim_zones z ON f.pickup_location_id = z.location_id
WHERE d.year = 2020
GROUP BY d.month_name, z.borough
```

Clean, readable, performant.

---

## SNOWFLAKE SCHEMA (Alternative - Less Common)

**Definition**: Dimensions are normalized (broken into sub-dimensions)

```
dim_borough → dim_zones → fct_trips
```

**Example:**
Instead of storing `borough` directly in `dim_zones`, you create a separate `dim_borough` table.

**Why Less Common:**
- ❌ More complex (more joins)
- ❌ Slower queries (extra hops)
- ✅ Saves space (but storage is cheap)
- ✅ Enforces more consistency

**Rule of Thumb**: Start with star schema. Only use snowflake if you have a good reason.

---

## SLOWLY CHANGING DIMENSIONS (SCD)

**The Problem**: What happens when dimension data changes over time?

Example: A taxi zone gets renamed, or boundaries change. How do you handle this?

### **Type 1 SCD: Overwrite** (Most Common)
**Strategy**: Just update the record, don't keep history

```sql
-- Before
location_id | zone_name
1           | East Harlem

-- After update
location_id | zone_name
1           | East Harlem North  -- Changed!
```

**Pros**: Simple  
**Cons**: You lose history

**When to use**: When history doesn't matter (typo fixes, minor updates)

---

### **Type 2 SCD: Track Full History** (Common in Analytics)
**Strategy**: Create a new row for each change, keep old rows

```sql
location_id | zone_name          | valid_from | valid_to   | is_current
1           | East Harlem        | 2020-01-01 | 2025-06-30 | false
2           | East Harlem North  | 2025-07-01 | 9999-12-31 | true
```

**Pros**: Complete history, can recreate any point in time  
**Cons**: More complex, larger tables

**When to use**: When you need to track changes (price changes, product categories, etc.)

**dbt Support**: dbt has built-in [snapshots](https://docs.getdbt.com/docs/build/snapshots) for Type 2 SCD

---

### **Type 3 SCD: Track Limited History** (Rare)
**Strategy**: Add columns for previous values

```sql
location_id | zone_name          | previous_zone_name
1           | East Harlem North  | East Harlem
```

**Pros**: Simple, tracks one change  
**Cons**: Only keeps last value

**When to use**: Rarely - usually Type 1 or Type 2 is better

---

## GRAIN: THE MOST IMPORTANT CONCEPT

**Grain** = What does one row in your fact table represent?

**Examples:**
- ✅ **One taxi trip**: Each row = 1 ride
- ✅ **One transaction**: Each row = 1 purchase
- ✅ **One daily summary**: Each row = metrics for 1 day

**Why It Matters:**
- Defines what you can and can't analyze
- Affects table size and performance
- Must be documented clearly

**Your Project Grain:**
```
fct_trips: One row = One individual taxi trip
```

**Questions to Ask:**
- Is this grain too detailed? (performance issues?)
- Is this grain too summarized? (lose analytical power?)
- Can I answer my business questions at this grain?

---

## APPLYING THIS TO YOUR NYC TAXI PROJECT

### **Your Raw Data:**
- Green taxi trips (2019-2020)
- Yellow taxi trips (2019-2020)
- Taxi zone lookup table

### **Your Target Structure:**

```
STAGING LAYER (Clean & Standardize)
├─ stg_green_taxi_trips
└─ stg_yellow_taxi_trips

INTERMEDIATE LAYER (Combine)
└─ int_trips_union (combines green + yellow)

MARTS LAYER (Dimensional Model)
├─ fct_trips (FACT TABLE)
│   • One row per trip
│   • Measures: fare, distance, duration, passenger_count
│   • FKs to dimensions
│
└─ dim_zones (DIMENSION TABLE)
    • One row per taxi zone
    • Attributes: borough, zone name, service zone
```

### **Example Analytical Questions You Can Answer:**

```sql
-- 1. Which borough generates the most revenue?
SELECT 
    z.borough,
    SUM(f.total_amount) as revenue
FROM fct_trips f
JOIN dim_zones z ON f.pickup_location_id = z.location_id
GROUP BY z.borough

-- 2. Average trip distance by payment type
SELECT 
    p.payment_type_name,
    AVG(f.trip_distance) as avg_distance
FROM fct_trips f
JOIN dim_payment_type p ON f.payment_type_id = p.payment_type_id
GROUP BY p.payment_type_name

-- 3. Monthly trends
SELECT 
    DATE_TRUNC('month', f.pickup_datetime) as month,
    COUNT(*) as total_trips,
    SUM(f.total_amount) as revenue
FROM fct_trips f
GROUP BY month
ORDER BY month
```

---

## DESIGN PRINCIPLES FOR YOUR dbt PROJECT

### 1. **Start with Business Questions**
What do stakeholders want to know? Design tables to answer those questions efficiently.

### 2. **Keep Facts Lean**
Only store measures and foreign keys. Push attributes to dimensions.

### 3. **Denormalize Dimensions**
Don't over-normalize. A bit of redundancy is OK for query speed.

### 4. **Document Grain Clearly**
In your dbt YAML files, always state what one row represents.

### 5. **Test Relationships**
Use dbt tests to ensure FKs actually exist in dimension tables.

---

## NORMALIZATION vs DIMENSIONAL MODELING

You might have learned **3NF (Third Normal Form)** in database classes. That's DIFFERENT.

| Aspect | 3NF (OLTP) | Dimensional (OLAP) |
|--------|------------|-------------------|
| Goal | Minimize redundancy | Maximize query performance |
| Writes | Many updates/inserts | Mostly inserts |
| Reads | Simple lookups | Complex aggregations |
| Structure | Normalized (many tables) | Denormalized (star schema) |
| Use Case | Applications (CRUD) | Analytics (BI, reporting) |

**Your Taxi Data:**
- OLTP: How it's stored in the taxi app database (normalized)
- OLAP: How you'll model it in BigQuery with dbt (dimensional)

---

## KEY TAKEAWAYS FOR STEP 2

1. **Two building blocks**: Facts (measures) + Dimensions (context)
2. **Star schema**: Fact in center, dimensions around it
3. **Grain**: Define what one row means (crucial!)
4. **SCD Types**: Type 1 (overwrite), Type 2 (history), Type 3 (rare)
5. **Denormalization is OK**: In analytics, speed > storage
6. **Your project**: Will follow this exact pattern

---

## QUIZ YOURSELF

Before moving to Step 3, answer these:
- [ ] What's the difference between a fact and a dimension?
- [ ] Why use a star schema instead of normalized tables?
- [ ] What is "grain" and why does it matter?
- [ ] How would you handle a taxi zone name change? (SCD Type?)
- [ ] In the NYC taxi project, what will be the grain of `fct_trips`?

---

## VISUAL REMINDER: Your End Goal

```
Raw Data (BigQuery)
      ↓
  [STAGING]
  Clean & Structure
      ↓
[INTERMEDIATE]
  Combine & Join
      ↓
   [MARTS] ← You're designing THIS
  Star Schema
  ├─ fct_trips
  └─ dim_zones
      ↓
  Dashboard
```

**When you're ready**: Reply and we'll move to Step 3 (Install dbt Core + BigQuery setup)
