# STEP 1: dbt Fundamentals & Philosophy
## Understanding What & Why


---

## THE BIG PICTURE: What Problem Does dbt Solve?

Imagine you're an analyst. Your company has data coming in from everywhere:
- Backend systems (user activity, transactions)
- Frontend apps (clicks, page views)
- Third-party APIs (weather, demographics)

**All of it lands in your data warehouse (BigQuery in your case).**

### Without dbt:
You write massive SQL scripts that are:
- ❌ Scattered across files with no structure
- ❌ Hard to reuse (copy-paste everywhere)
- ❌ No automated testing of data quality
- ❌ No way to track changes (no version control)
- ❌ No clear dependencies between transformations
- ❌ Production breaks with no safety net

### With dbt:
You get software engineering best practices for analytics code:
- ✅ **Version control** — transformations live in git
- ✅ **Modularity** — reusable pieces instead of spaghetti queries
- ✅ **Testing** — automated data quality checks
- ✅ **Documentation** — auto-generated, never out of date
- ✅ **Environments** — separate dev and prod sandboxes
- ✅ **CI/CD** — deployments with validation and rollback

---

## HOW DOES dbt ACTUALLY WORK?

### The Simple Version:
1. You write a **normal SELECT statement** in a `.sql` file
2. dbt **compiles** it (adds some magic like Jinja templating)
3. dbt **runs it** against your warehouse
4. dbt **stores the result** as a table or view
5. dbt **manages dependencies** (runs things in the right order)

### The Magic: You DON'T Write `CREATE TABLE` Statements

Instead of:
```sql
CREATE TABLE my_dataset.my_table AS
SELECT * FROM raw_data WHERE ...
```

You just write:
```sql
SELECT * FROM {{ source('raw', 'trips') }} 
WHERE trip_distance > 0
```

dbt handles the table creation, the schema management, everything.

---

## KEY CONCEPTS TO UNDERSTAND

### 1. **dbt Models**
A model is just a `.sql` file that contains a `SELECT` statement. That's it.
- Each model = one transformation
- dbt runs all models and creates tables/views from them
- Models can reference other models (dependencies)

### 2. **The Three Layers of dbt Projects**

```
Raw Data (BigQuery)
       ↓
   [STAGING] — Clean, structure, light transformations
       ↓
[INTERMEDIATE] — Join data, apply business logic
       ↓
    [MARTS] — Final analytical tables/views (facts & dimensions)
       ↓
   BI Tools / Analytics
```

**Why three layers?**
- Staging: Source of truth for cleaned data
- Intermediate: Combines multiple sources, applies logic
- Marts: Ready for consumption (dimensional modeling)

### 3. **ref() and source() Functions**
These are how dbt understands dependencies:

```sql
-- ref() points to another dbt model
SELECT * FROM {{ ref('staging_green_taxi') }}

-- source() points to raw data in your warehouse
SELECT * FROM {{ source('raw', 'green_taxi_data') }}
```

dbt uses these to:
- Know which order to run models
- Auto-generate lineage diagrams
- Track data quality through the pipeline

### 4. **Materialization Types**
How dbt stores your final result:

- **View** (default): Light, not stored, runs on query
  - Good for: Quick lookups, staging models
  
- **Table**: Stored in warehouse, fast queries
  - Good for: Final marts, heavy queries
  
- **Incremental**: Only adds new/changed data
  - Good for: Large fact tables, cost optimization
  
- **Ephemeral**: Temporary CTEs (not stored)
  - Good for: Internal intermediate transformations

### 5. **Dependencies & Execution Order**
dbt automatically figures out what to run when:
```
raw_data
  ├─→ stg_green_taxi
  │     └─→ int_taxi_unions
  │           └─→ fct_trips ← needs staging first
  │
  └─→ stg_yellow_taxi
        └─→ int_taxi_unions
```

Run `dbt build` once, it executes in correct order.

---

## dbt CORE vs dbt CLOUD (You're Using CORE)

| Feature | dbt Core | dbt Cloud |
|---------|----------|-----------|
| **Install** | Local machine | Web-based IDE |
| **Cost** | Free | Free (Developer plan) |
| **Orchestration** | You handle (cron, Airflow) | Built-in job scheduler |
| **Documentation** | Self-hosted | Hosted by dbt |
| **Learning curve** | Steeper | Easier |
| **Control** | Maximum | Limited |

**You're using Core** because:
- More hands-on learning
- Full control over the environment
- Can integrate with existing tools (Airflow, etc.)
- Perfect for understanding "how dbt really works"

---

## YOUR PROJECT: By End of Week 4

You'll have built a complete dbt project that:

```
Raw NYC Taxi Data (BigQuery)
    ↓
[Staging Models]
  - stg_green_taxi.sql
  - stg_yellow_taxi.sql
    ↓
[Intermediate Models]
  - int_taxi_unions.sql
    ↓
[Analytical Models (Marts)]
  - fct_trips.sql (fact table)
  - dim_passenger.sql (dimension table)
    ↓
Ready for Dashboard / Analysis
```

Each with:
- ✅ Tests (data quality checks)
- ✅ Documentation (descriptions, lineage)
- ✅ Version control (git)
- ✅ Production-ready code

---

## KEY TAKEAWAYS FOR STEP 1

1. **dbt solves the chaos problem**: Turns scattered SQL into organized, tested, documented code
2. **Three-layer approach**: Staging → Intermediate → Marts (this is industry standard)
3. **Models are just SQL**: `ref()` and `source()` are your dependency management
4. **dbt Core is the engine**: You're learning the real thing, not a wrapper
5. **Next step**: Data modeling (understanding how to structure your tables)

---

## QUIZ YOURSELF

Before moving to Step 2, answer these:
- [ ] What does `ref()` do?
- [ ] What's the difference between a view and a table materialization?
- [ ] Why would you use three layers instead of one big transformation?
- [ ] What does dbt do with your `CREATE TABLE` statement?

**When you're ready**: Reply and we'll move to Step 2 (Data Modeling)
