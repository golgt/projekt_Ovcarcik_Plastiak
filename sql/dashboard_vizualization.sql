-- 1.Príspevok sektorov k výkonnosti portfólia (Total Effect)
SELECT
    ds.grouping_name AS sector,
    dac.asset_class_name,
    SUM(f.metric_value) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector ds ON f.sector_id = ds.sector_id
JOIN dim_asset_class dac ON f.asset_class_id = dac.asset_class_id
JOIN dim_measure_type dmt ON f.measure_type_id = dmt.measure_type_id
WHERE dmt.measure_name = 'TOTAL_EFFECT'
GROUP BY ds.grouping_name, dac.asset_class_name;

-- 2.Váhy sektorov v portfóliu
SELECT s.grouping_name AS sector, SUM(f.metric_value) AS portfolio_weight
FROM fact_portfolio_analytics f JOIN dim_sector s
ON f.sector_id = s.sector_id
JOIN  dim_measure_type m ON f.measure_type_id = m.measure_type_id
WHERE m.measure_name = 'PORT_WEIGHT'
GROUP BY s.grouping_name
ORDER BY portfolio_weight DESC;

-- 3.Sektorová expozícia a sektorový efekt
SELECT 
s.grouping_name AS sector, SUM(CASE WHEN m.measure_name = 'PORT_WEIGHT' THEN f.metric_value END) AS portfolio_weight,
SUM(CASE WHEN m.measure_name = 'TOTAL_EFFECT' THEN f.metric_value END) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector s ON f.sector_id = s.sector_id
JOIN dim_measure_type m ON f.measure_type_id = m.measure_type_id
GROUP BY s.grouping_name;

-- 4.Kombinované porovnanie účtov (váha + efekt))
SELECT
    f.account_id,
    s.grouping_name AS sector,
    SUM(CASE WHEN f.measure_type_id = 3 THEN f.metric_value END) AS portfolio_weight,
    SUM(CASE WHEN f.measure_type_id = 5 THEN f.metric_value END) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector s ON f.sector_id = s.sector_id
GROUP BY f.account_id, s.grouping_name
ORDER BY s.grouping_name, f.account_id;

-- 5.Celkový vplyv podľa sektora
SELECT 
s.grouping_name AS sector,
SUM(f.metric_value) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector s ON f.sector_id = s.sector_id
JOIN dim_measure_type m ON f.measure_type_id = m.measure_type_id
WHERE m.measure_name = 'TOTAL_EFFECT'
GROUP BY s.grouping_name
ORDER BY total_effect DESC;

--6.Weight vs Effect
SELECT ds.grouping_name AS sector,
    SUM(CASE WHEN dmt.measure_name = 'PORT_WEIGHT' THEN f.metric_value END) AS port_weight,
    SUM(CASE WHEN dmt.measure_name = 'TOTAL_EFFECT' THEN f.metric_value END) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_measure_type dmt ON f.measure_type_id = dmt.measure_type_id
JOIN dim_sector ds ON f.sector_id = ds.sector_id
GROUP BY ds.grouping_name;

--7.Porovnanie sektorových váh portfólia a benchmarku
SELECT ds.grouping_name as sector,
    SUM(CASE WHEN dmt.measure_name = 'PORT_WEIGHT' THEN f.metric_value END) AS portfolio_weight,
    SUM(CASE WHEN dmt.measure_name = 'BENCH_WEIGHT' THEN f.metric_value END) AS benchmark_weight
FROM fact_portfolio_analytics f
JOIN dim_measure_type dmt ON f.measure_type_id = dmt.measure_type_id
JOIN dim_sector ds ON f.sector_id = ds.sector_id
WHERE dmt.measure_name IN ('PORT_WEIGHT', 'BENCH_WEIGHT')
GROUP BY ds.grouping_name
ORDER BY ds.grouping_name;
