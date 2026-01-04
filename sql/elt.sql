SUSE WAREHOUSE PONY_WH;
USE DATABASE PONY_DB;
CREATE OR REPLACE SCHEMA projekt;
USE SCHEMA projekt;

//vytvorenie staging tabulky
CREATE OR REPLACE TABLE  pa_metadata_staging AS 
SELECT * FROM factset_analytics_sample.fds.pa_metadata;

SELECT * FROM pa_metadata_staging; // kontrola či sa dáta správne načítali do tabuľky

CREATE OR REPLACE TABLE  metadata_weights_example_staging AS 
SELECT * FROM factset_analytics_sample.fds.metadata_weights_example;

SELECT * FROM metadata_weights_example_staging LIMIT 15; 

CREATE OR REPLACE TABLE  eq_sector_attribution_staging AS 
SELECT * FROM factset_analytics_sample.fds.eq_sector_attribution;

SELECT * FROM eq_sector_attribution_staging LIMIT 15;

CREATE OR REPLACE TABLE  eq_sector_exposures_staging AS 
SELECT * FROM factset_analytics_sample.fds.eq_sector_exposures;

SELECT * FROM eq_sector_exposures_staging LIMIT 15;

CREATE OR REPLACE TABLE  returns_staging AS 
SELECT * FROM factset_analytics_sample.fds.returns;
//b188th (4)
SELECT * FROM returns_staging LIMIT 15;

CREATE OR REPLACE TABLE  fi_sector_attribution_staging AS 
SELECT * FROM factset_analytics_sample.fds.fi_sector_attribution;

SELECT * FROM fi_sector_attribution_staging LIMIT 15;

CREATE OR REPLACE TABLE  fi_sector_exposures_staging AS 
SELECT * FROM factset_analytics_sample.fds.fi_sector_exposures;

SELECT * FROM fi_sector_exposures_staging LIMIT 15;

CREATE OR REPLACE TABLE  characteristics_staging AS 
SELECT * FROM factset_analytics_sample.fds.characteristics;

SELECT * FROM characteristics_staging LIMIT 15;

CREATE OR REPLACE TABLE  holdings_staging AS 
SELECT * FROM factset_analytics_sample.fds.holdings;

SELECT * FROM holdings_staging;

//vytváranie tabuľky faktov a dimenzií
CREATE OR REPLACE TABLE dim_account AS(
    SELECT account_id,
        account_name,
        base_currency,
        benchmark_name,
        inception_date
    FROM pa_metadata_staging
    );

SELECT * FROM dim_account; //kontrola dimenzionálnej tabuľky

CREATE OR REPLACE TABLE dim_date AS
    SELECT DISTINCT 
        TO_NUMBER(TO_CHAR(date_col,'YYYYMMDD')) AS DATE_ID,
        date_col AS FULL_DATE,
        YEAR(date_col) AS YEAR,
        MONTH(date_col) AS MONTH,
        //QUATER(date_col) AS QUATER
    FROM(
        SELECT CAST(calculation_date AS DATE) AS date_col FROM returns_staging
        UNION
        SELECT CAST(DATE AS DATE) FROM eq_sector_exposures_staging
        UNION
        SELECT CAST(DATE AS DATE) FROM fi_sector_exposures_staging
        UNION
        SELECT CAST(STARTDATE AS DATE) FROM eq_sector_attribution_staging
        UNION
        SELECT CAST(STARTDATE AS DATE) FROM fi_sector_attribution_staging
    ) t
WHERE DATE_COL IS NOT NULL;

select * from dim_date;

CREATE OR REPLACE TABLE dim_asset_class AS 
    SELECT 1 AS asset_class_id, 'EQ' AS ASSET_CLASS_NAME
    UNION ALL
    SELECT 2 AS asset_class_id, 'FI' AS ASSET_CLASS_NAME;
    
select * from dim_asset_class;

CREATE OR REPLACE TABLE dim_sector AS 
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY GROUPINGNAME) AS sector_id,
    GROUPINGNAME AS grouping_name,
    parentgrouping AS parent_grouping,
    groupinghierarchy AS grouping_hierarchy,
    level,
    level2
FROM(
SELECT GROUPINGNAME, parentgrouping, groupinghierarchy, level, level2 FROM eq_sector_exposures_staging
UNION
SELECT GROUPINGNAME, parentgrouping, groupinghierarchy, level, level2 FROM fi_sector_exposures_staging
);

SELECT * FROM dim_sector;

CREATE OR REPLACE TABLE dim_security AS 
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY SEDOL) AS security_id,
    sedol,
    sector,
    market_cap,
    portfoliocurcode AS PORTFOLIO_CURRENCY
FROM holdings_staging
WHERE sedol IS NOT NULL;

SELECT * FROM dim_security;

CREATE OR REPLACE TABLE dim_measure_type AS 
SELECT 1 AS measure_type_id, 'PORT_RETURN' AS measure_name, 'RETURN' AS measure_category
UNION ALL
SELECT 2, 'BENCH_RETURN', 'RETURN'
UNION ALL
SELECT 3, 'PORT_WEIGHT', 'WEIGHT'
UNION ALL
SELECT 4, 'BENCH_WEIGHT', 'WEIGHT'
UNION ALL
SELECT 5, 'TOTAL_EFFECT', 'EFFECT'
UNION ALL
SELECT 6, 'ALLOCATION_EFFECT', 'EFFECT';

SELECT * FROM dim_measure_type;

CREATE OR REPLACE TABLE fact_portfolio_analytics (
    fact_id INT AUTOINCREMENT PRIMARY KEY,
    account_id VARCHAR(50),
    date_id INT,
    sector_id INT,
    asset_class_id INT,
    measure_type_id INT,
    metric_value FLOAT
);

INSERT INTO fact_portfolio_analytics (
    account_id,
    date_id,
    sector_id,
    asset_class_id,
    measure_type_id,
    metric_value
)
SELECT
    e.acct AS account_id,
    d.date_id,
    s.sector_id,
    1 AS asset_class_id,              -- EQ
    3 AS measure_type_id,             -- PORT_WEIGHT
    e.port_weight AS metric_value
FROM eq_sector_exposures_staging e
JOIN dim_date d
    ON d.full_date = CAST(e.date AS DATE)
JOIN dim_sector s
    ON s.grouping_name = e.groupingname
WHERE e.port_weight IS NOT NULL;

SELECT * FROM fact_portfolio_analytics;

INSERT INTO fact_portfolio_analytics (
    account_id,
    date_id,
    sector_id,
    asset_class_id,
    measure_type_id,
    metric_value
)
SELECT
    a.acct,
    d.date_id,
    s.sector_id,
    1,                               -- EQ
    5,                               -- TOTAL_EFFECT
    a.total_effect
FROM eq_sector_attribution_staging a
JOIN dim_date d
    ON d.full_date = CAST(a.startdate AS DATE)
JOIN dim_sector s
    ON s.grouping_name = a.groupingname
WHERE a.total_effect IS NOT NULL;

    