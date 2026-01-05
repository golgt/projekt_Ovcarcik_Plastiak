# **ELT proces datasetu FactSet Analytics (sample)**

V tomto repozitári sa nachádza implementácia ELT procesu v Snowflake a vytvorenie dátového skladu so schémou Star schema. V projekte pracujeme s **FactSet Analytics (sample)** datasetom ktorý je voľne dostupný na Snowflake marketplace. Projekt je analytická databáza na výkonnostnú analýzu investičných portfólií (performance, attribution, exposure) voči benchmarkom – pre akcie (EQ) aj dlhopisy (FI). Výsledný dátový model umožnuje multidimenzionálnu analýzu a vyzualizáciu kľúčových metrik.  

---
## **1. Úvod a popis zdrojových dát**
V tomto projekte analyzujeme dáta o finančných portfóliách, ktoré obsahujú podrobné informácie o účtoch, cenných papieroch a ich výkonnosti v čase. Databáza obsahuje rôzne zdrojové tabuľky, ktoré umožňujú komplexnú analýzu portfólií a benchmarkov. Cieľom je porozumieť:
-ako sa váhy a zloženie portfólia menia v čase a voči benchmarku,
-ktoré sektory a cenné papiere prispievajú najviac k výnosu portfólia,
-vplyvu alokačných, selekčných a menových efektov na celkový výnos,
-rizikovým profilom portfólia a jeho citlivosti na trhové zmeny.

Zdrojové dáta pochádzajú z Snowflake datasetu dostupného [tu](https://app.snowflake.com/marketplace/listing/GZT0ZGCQ51UP/factset-factset-analytics-sample?search=FactSet+Analytics+%28sample%29). Na náš projekt sme si vybrali FactSet Analytics (sample) dataset ktorý obsahuje tabuľky:

- `CHARACTERISTICS` – Tabuľka, ktorá uchováva finančné údaje na úrovni účtu alebo portfólia
- `EQ_SECTOR_ATTRIBUTION` – Tabuľka pre equity sektorovú atribučnú analýzu, ktorá porovnáva výkonnosť portfólia a benchmarku
- `EQ_SECTOR_EXPOSURES` – Tabuľka, ktorá zobrazuje expozície akciového portfólia voči jednotlivým sektorom alebo cenným papierom v porovnaní s benchmarkom
- `FI_SECTOR_ATTRIBUTION` – Tabuľka pre atribučnú analýzu výkonnosti dlhopisového portfólia
- `FI_SECTOR_EXPOSURES` – Tabuľka, ktorá zobrazuje sektorové expozície dlhopisového
- `HOLDINGS` – Tabuľka s detailnými informáciami o jednotlivých pozíciách v portfóliu a benchmarku
- `METADATA_WEIGHTS_EXAMPLE` – ukážková Tabuľka, ktorá porovnáva váhy portfólia a benchmarku podľa skupín alebo cenných papierov a zobrazuje ich rozdiely v čase spolu s identifikačnými a hierarchickými údajmi
- `PA_METADATA` – Tabuľka, ktorá popisuje nastavenia, identitu a časový rozsah portfólia a reportov používaných v analytických výpočtoch.
- `RETURNS` – Tabuľka, ktorá uchováva výnosy portfólia a jeho benchmarku za jednotlivé obdobia, vrátane dátumu výpočtu, frekvencie výnosov a meny portfólia.

Účelom ELT procesu je tieto dáta pripraviť, transformovať, a sprístupniť pre viacdimenzionálnu analýzu.

---
### **1.1 Dátová architektúra**
### **ERD diagram**

Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame (ERD):

<p align="center">
  <img width="1333" height="1329" alt="ERD" src="https://github.com/user-attachments/assets/98b5f7e2-85f7-4551-98b8-e78a93c32fa6" alt="ERD Schéma"/>
  <br>
  <em>Obrázok 1 Entitno-relačná schéma FactSet Analytics</em>
</p>

---
## **2. Dimenzionálny model**

V projekte bola navrhnutá schéma hviezdy (star schema) podľa Kimballovej metodológie, ktorá obsahuje jednu faktovú tabuľku `Fact_table`, prepojenú s viacerými dimenzionálnymi tabuľkami. Tento model umožňuje efektívnu analytiku výkonnosti, expozícií a atribúcie finančných portfólií.
Faktová tabuľka je prepojená s nasledujúcimi dimenziami:
- `dim_account` - Obsahuje základné informácie o investičných účtoch a portfóliách, ako sú identifikátor účtu, názov účtu, základná mena, benchmark a dátum vzniku portfólia. Táto dimenzia umožňuje analyzovať výkonnosť podľa jednotlivých portfólií.
- `dim_date` - Zahŕňa kalendárne informácie o dátumoch, ku ktorým sa viažu jednotlivé metriky, ako sú deň, mesiac, rok a štvrťrok. Dimenzia umožňuje časové analýzy a sledovanie vývoja výkonnosti v čase.
- `dim_asset_class` - Obsahuje informácie o triede aktív, napríklad akcie (EQ) alebo dlhopisy (FI). Táto dimenzia umožňuje porovnávať výkonnosť a expozície medzi rôznymi typmi finančných nástrojov.
- `dim_sector` - Obsahuje sektorové a hierarchické členenie investícií, vrátane názvu sektora, nadradeného sektora a úrovne v hierarchii. Dimenzia umožňuje sektorovú analýzu portfólia a benchmarku.
- `dim_security` - Obsahuje detailné informácie o jednotlivých cenných papieroch, ako sú názov, symbol a identifikátory cenných papierov. Táto dimenzia umožňuje analýzu výkonnosti na úrovni konkrétnych investícií.
- `dim_measure_type` - Definuje typy meraných metrík, ako sú výnosy, váhy alebo atribučné efekty (napr. alokačný alebo selekčný efekt). Táto dimenzia určuje význam číselných hodnôt uložených vo faktovej tabuľke.

Štruktúra hviezdicového modelu je znázornená na ER diagrame, ktorý zobrazuje prepojenia medzi faktovou tabuľkou a jednotlivými dimenziami. Takýto návrh zjednodušuje dotazovanie, zlepšuje výkon analytických dotazov a umožňuje flexibilné rozširovanie modelu o ďalšie metriky alebo dimenzie.
<p align="center">
  <img width="1073" height="714" alt="Star_scheme" src="https://github.com/user-attachments/assets/773ca867-9f16-41b9-9b7c-015b0f0f0def" alt="Star schéma" />
  <br>
  <em>Obrázok 2 Star schéma FactSet Analytics</em>
</p>

---
## **3. ELT proces v Snowflake**

ELT -- Extract, Load, Transform -- je proces v Snowflake ktorý zahŕňa načítavanie survých dát priamo do cloudového dátového skladu. Po načítaní do skladu sa použijú výkonné a škálovateľné výpočty Snowflake na vykonanie transformácií v rámci skladu. Na rozdiel od tradičného ELT, ktoré dáta pred načítaním transformuje, využíva oddelenie úložiska a výpočtov pre efektívnosť, vďaka čomu je ELT ideálny na efektívne spracovanie veľkých a rozmanitých súborov údajov. Snowflake v ELT vyniká a používa nástroje ako **Snowpipe** na prijímanie dát, **Streams** pre CDC (Change Data Capture), **Tasks** na plánovanie a **SQL/Python** na transformácie čo z neho robí moderný a nákladovo efektívny prístup v porovnaní so staršími metódami ELT.

### **Kľúčové výhody ELT so Snowflake**

- **Škálovatelnosť a výkon** -- Oddelené úložisko a výpočtové kapacity Snowflake umožňujú  masívne škálovanie transformačných úloh na požiadanie.
- **Flexibilita** -- Nespracované dáta sú vždy k dispozícií, čo umožňuje iteratívne transformácie podľa meniacich sa obchodných potrieb, na rozdiel od ELT, ktoré uzamyká transformácie v predstihu.
- **Cenová efektívnosť** -- Platí sa iba za výpočtové kapacity použité počas transformácií s možnosťou škálovania, keď nie sú potrebné.
- **Jednoduchosť** -- Eliminuje zložité transformačné kanály s predbežným načítaním, čím zefektívňuje presun dát.  

---
### **3.1 Extract (Extrahovanie dát)**

Exhtrahovanie (Extract) - dáta sa získavajú z rôznych zdrojov ako napríklad databázy, súbory, rôzne datasety... <br>
Keďže náš zdroj je Snowflake marketplace tak sme museli v marketplace dať „subscribe“ na dataset aby sme mohli s databázou pracovať. Následne sa vytvoril secure share dát čo znamená že dáta máme logicky dostupné, ale fyzicky ostali u poskytovaťeľa v tomto prípade FactSet.

---
### **3.2 Load (Načítanie dát)**

Load (načítanie) - surové, netransformované dáta sa načítajú priamo do úložnej vrstvy Snowflake, často pomocou príkazov COPY alebo Snowpipe na streamovanie, čím sa okamžite sprístupnia.

**Príklad kódu:**
```sql
CREATE OR REPLACE TABLE  pa_metadata_staging AS 
SELECT * FROM factset_analytics_sample.fds.pa_metadata;
```

Po vytvorení tabuľky sme si hňed aj kontrolovali či nám to správne načítalo dáta do tabuľky pomocou:

```sql
SELECT * FROM pa_metadata_staging LIMIT 15;;
```

---
### **3.3 Transform (Transformácia dát)**

Transform - je fáza v ELT procese ktorá predstavuje spracovanie, čistenie a modelovanie dát priamo v databáze po ich nahraní do *raw/staging vrstvy*. Cieľom tejto fázy je pripraviť dáta do štruktúry vhodnej na analytické spracovanie a reporting. V tejto fáze sa vytvárajú dimenzionálne tabuľky a tabuľka faktov.

Dimenzie boli navrhnuté tak aby poskytovali kontext pre tabuľku faktov. Dimenzionálna tabuľka `dim_date` predstavuje časovú dimenziu, ktorá slúžia na analízu dát v čase a umožnuje agregáciu metrík na rôznych časových úrovniach, ako sú deň, mesiac alebo rok. Je vytvorená spojením všetkých dátumových hodnôt zo staging vrstvy a poskytuje jetnotný časový kontext pre tabuľku faktov.

#### **Štruktúra dimenzie**

Dimenzia obsahuje:
- `date_id` - technický identifikátor dátumu vo formáte **YYYYMMDD**
- `full_date` - skutočná dátumová hodnota
- `year`, `month` - údaje o roku a mesiaci
Tieto atribúty sú odvodené priamo z dátumovej hodnoty a nemenia svoj význam v čase.

V transformačnej fáze ELT procesu sú zhromaždené všetky unikátne dátumy zo zdrojových tabuliek. Všetky dátumy sa konvertovali na jednotný dátový formát typu `DATE`. Pre každý kalendárny de§ň sa vytvoril jeden záznam a odstránili sa všetky NULL hodnoty.

#### **SCD v dim_date**

Dimenzionálna tabuľka `dim_date` je navrhnutá ako **SCD Type 0** čiže je to nemenná dimenzia. SCD 0 Je to pretože dátum nemení svoj význam, rok, mesiac, deň sú pevne dané, historizácia zmien nemá zmysel. Z tohto dôvodu slúži ako stabilná referenčná dimenzia.

**Príklad kódu:**

```sql
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT 
    TO_NUMBER(TO_CHAR(date_col,'YYYYMMDD')) AS date_id,
    date_col AS full_date,
    YEAR(date_col) AS year,
    MONTH(date_col) AS month
FROM (
    SELECT CAST(calculation_date AS DATE) AS date_col FROM returns_staging
    UNION
    SELECT CAST(date AS DATE) FROM eq_sector_exposures_staging
    UNION
    SELECT CAST(date AS DATE) FROM fi_sector_exposures_staging
    UNION
    SELECT CAST(startdate AS DATE) FROM eq_sector_attribution_staging
    UNION
    SELECT CAST(startdate AS DATE) FROM fi_sector_attribution_staging
) t
WHERE date_col IS NOT NULL;
```

Dimenzia `dim_sector` reprezentuje sektorovú klasifikáciu finančných nástrojov a slúži ako popisná dimenzia pre analytické hondotenie výkonnosti a alokácie portfólia. Poskytuje hierarchycký pohľad na sektory a umožnuje agregáciu metrík na rôznych úrovniach sektorovej štruktúry.

Dimenzia je vytvorená spojením sektorových údajov z dvoch staging tabuliek -- `EQ_SECTOR_EXPOSURES_STAGING` (equity aktíva), `FI_SECTOR_EXPOSURES_STAGING` (fixed income aktíva). Tieto zdroje sú zlúčené pomocou **UNION**, čím sa zabezpečí jednotná sektorová klasifikácia naprieč celým portfóliom. Použitím **SELECT DISTINCT** sú odstránené duplicitné záznamy a je zachovaná jednoznačnosť sektorových kombinácií.   

#### **Štruktúra dimenzie**

Dimenzia obsahuje:
- `sector_id` - surrogate kľúč generovaný v dátovom sklade,
- `grouping_name` - názov sektoru,
- `parent_groupings` - nadradený sektor v hierarchií,
- `grouping_hierarchy` - identifikátor sektorovej hierarchie,
- `level`, `level2` - úrovne sektorovej klasifikácie,
- `valid_from`, `valid_to` -- technická platnosť záznamu,
- `is_current` - príznak aktuálnej verzie záznamu.

#### **SCD v dim_sector**

Dimenzionálna tabuľka `dim_sector` je navrhnutá ako **SCD Type 2** pretože sektorová klasifikácia sa v čase môže mieniť (reklasifikácie, zmena hierarchie), historická konzistentnosť analytických výstupov je kľúčová a každá zmena sektorových atribútov je reprezentovaná novým záznamom. V aktuálnej implementácií sú všetky záznamy vložené ako aktuálne (*is_current = TRUE*) s platnosťou (*valid_to = '2027-2-28'*). Návrh je pripravený na historizáciu zmien bez zásahu do faktových dát.

**Príklad kódu:**
```sql
CREATE OR REPLACE TABLE dim_sector AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY groupingname) AS sector_id,
    groupingname AS grouping_name,
    parentgrouping AS parent_grouping,
    groupinghierarchy AS grouping_hierarchy,
    level,
    level2,
    CURRENT_DATE() AS valid_from,
    '2027-2-28' AS valid_to,
    TRUE AS is_current
FROM (
    SELECT groupingname, parentgrouping, groupinghierarchy, level, level2
    FROM eq_sector_exposures_staging
    UNION
    SELECT groupingname, parentgrouping, groupinghierarchy, level, level2
    FROM fi_sector_exposures_staging
);
```
Faktová tabuľka `fact_portfolio_analytics` ukladá *meratelné hodnoty*(metrics) preportfólia. Každý riadok predstavuje **jednu konkrétnu metriku** pre:
- konkrétny účet
- konkrétny dátum
- konkrétny sektor
- konkrétnu asset class
- konkrétny typ merania(measure type)

Tabuľka reprezentuje jednu metriku pre jeden účet, v jeden deň, pre jeden sektor, pre jednu asset class, pre jeden measure type.

**Príklad kódu:**
```sql
CREATE OR REPLACE TABLE fact_portfolio_analytics (
    fact_id INT AUTOINCREMENT PRIMARY KEY,
    account_id VARCHAR(50),
    date_id INT,
    sector_id INT,
    asset_class_id INT,
    measure_type_id INT,
    metric_value FLOAT
);
```

Do tabuľky sme vložili dva rôzne typy metriky pre rovnakú granularitu:
- **PORT_WEIGHT**
- **TOTAL_EFFECT**

#### **Insert PORT_WEIGHT**

```sql
FROM eq_sector_exposures_staging e
```

Toto je typicý *exposure fact*:
- `port_weight` - váha sektora v portfóliu
- asset_class_id - 1(Equity)
- measure_type_id - 3(PORT_WEIHGT)

Každý riadok hovorí „V teno deň mal účet X v sektore Y váhu Z %.“ 

**Príklad kódu:***
```sql
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
```

#### **Insert TOTAL_EFFECT**

```sql
FROM eq_sector_attribution_staging a
```

Toto je *attribution fact*:
- `total_effect` - efekt sektora na výkonnosť portfólia
- asset_class_id - 1(Equity)
- measure_type_id - 5(TOTAL_EFFECT)

Každý riadok hovorí „V teno deň mal sektor Y efekt Z na výkonnosť účtu X.“ 

**Príklad kódu:**
```sql
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
```

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta nahraté do finálnej štruktúry. Na záver boli staging tabuľky odstránené aby sa optimalizovalo využitie úložiska:

**Príklad kódu:**
```sql
DROP TABLE IF EXISTS CHARACTERISTICS_STAGING;
DROP TABLE IF EXISTS EQ_SECTOR_ATTRIBUTION_STAGING;
DROP TABLE IF EXISTS EQ_SECTOR_EXPOSURES_STAGING;
DROP TABLE IF EXISTS FI_SECTOR_ATTRIBUTION_STAGING;
DROP TABLE IF EXISTS FI_SECTOR_EXPOSURES_STAGING;
DROP TABLE IF EXISTS HOLDINGS_STAGING;
DROP TABLE IF EXISTS METADATA_WEIGHTS_EXAMPLE_STAGING;
DROP TABLE IF EXISTS PA_METADATA_STAGING;
DROP TABLE IF EXISTS RETURNS_STAGING;
```

---
## **4. Vyzualizácia dát**
 
Dashboard obsahuje 7 vizualizácií ktoré poskytujú prehľad o ektorovej alokácii portfólia, jej porovnaní s benchmarkom a príspevku jednotlivých sektorov k celkovej výkonnosti portfólia. Cieľom dashboardu je identifikovať kľúčové sektory ovplyvňujúce výkonnosť, analyzovať alokáciu portfólia obroti benchmarku.  Využíva hviezdicovú (star) schému dátového modelu, kde faktovú tabuľku fact_portfolio_analytics dopĺňajú dimenzie sektorov, tried aktív, typov metrík a účtov.

<p align="center">
  <img width="1333" height="1329" alt="ERD" src="https://github.com/golgt/projekt_Ovcarcik_Plastiak/blob/main/img/dashboard1.png" alt="Dashboard obr.1"/>
  <br>
  <em>Obrázok 3 Dashboard FactSet Analytics 1</em>
</p>
<p align="center">
  <img width="1333" height="1329" alt="ERD" src="https://github.com/golgt/projekt_Ovcarcik_Plastiak/blob/main/img/dashboard2.png" alt="Dashboard obr.2"/>
  <br>
  <em>Obrázok  Dashboard FactSet Analytics 2</em>
</p>

  
---
### **Graf 1: Príspevok sektorov k výkonnosti portfólia (Total Effect)**

Táto vizualizácia zobrazuje celkový príspevok jednotlivých sektorov k výkonnosti portfólia, rozdelený podľa aktív(EQ/FI). Graf identifikuje sektory, ktoré najviac pozitívne alebo negatívne prispievajú k celkovej výkonnosti portfólia a umožnuje porovnanie medzi akciovou a dlhopisovou zložkou.

**Príklad kódu:**
```sql
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
```

---
### **Graf 2: Váhy sektorov v portfóliu**

Táto vizualizácia zobrazuje rozdelenie váh portfólia medzi jednotlivé sektory. Graf poskytuje rýchly prehľad o tom, ktoré sektory majú v portfóliu najväčšie zastúpenie a ktoré sú marginálne.

**Príklad kódu:**
```sql
SELECT s.grouping_name AS sector, SUM(f.metric_value) AS portfolio_weight
FROM fact_portfolio_analytics f JOIN dim_sector s
ON f.sector_id = s.sector_id
JOIN  dim_measure_type m ON f.measure_type_id = m.measure_type_id
WHERE m.measure_name = 'PORT_WEIGHT'
GROUP BY s.grouping_name
ORDER BY portfolio_weight DESC;
```

---
### **Graf 3: Sektorová expozíca a sektorový efekt**

Táto vizualizácia zobrazuje vsťah medzi váhou sektora v portfóliu a jeho príspevkom k výkonnosti. Graf umožňuje identifikovať sektory s vysokou váhou a pozitívnym efektom(silné sektory), sektory s vysokou váhou a negatívnym efektom(rizikové sektory), sektory s nízkou váhou, ale vysokým efektom(potenciál na navýšenie alokácie).

**Príklad kódu:**
```sql
SELECT 
s.grouping_name AS sector, SUM(CASE WHEN m.measure_name = 'PORT_WEIGHT' THEN f.metric_value END) AS portfolio_weight,
SUM(CASE WHEN m.measure_name = 'TOTAL_EFFECT' THEN f.metric_value END) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector s ON f.sector_id = s.sector_id
JOIN dim_measure_type m ON f.measure_type_id = m.measure_type_id
GROUP BY s.grouping_name;
```

---
### **Graf 4: Kombinované porovnanie účtov(váha + efekt)**

Táto vizualizácia zobrazuje porovnanie sektorových váh a ich vplyvu na výkonnosť nedzi rôznymi účtami/portfóliami. Graf umožnuje porovnať rozdiely v alokácií a výkonnosti sektorov medzi viacerými portfóliami a identifikovať rozdielne investičné stratégie.

**Príklad kódu:**
```sql
SELECT
    f.account_id,
    s.grouping_name AS sector,
    SUM(CASE WHEN f.measure_type_id = 3 THEN f.metric_value END) AS portfolio_weight,
    SUM(CASE WHEN f.measure_type_id = 5 THEN f.metric_value END) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector s ON f.sector_id = s.sector_id
GROUP BY f.account_id, s.grouping_name
ORDER BY s.grouping_name, f.account_id;
```

---
### **Graf 5: Celkový vplyv podľa sektora**

Táto vizualizácia zobrazuje agregovaný príspevok každého sektora k výkonnosti portfólia bez rozlíšenia tried aktív. Graf zvýrazňuje sektory s najväčším pozitívnym alebo negatívnym dopadom na celkový výkon portfólia.

**Príklad kódu:**
```sql
SELECT 
s.grouping_name AS sector,
SUM(f.metric_value) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_sector s ON f.sector_id = s.sector_id
JOIN dim_measure_type m ON f.measure_type_id = m.measure_type_id
WHERE m.measure_name = 'TOTAL_EFFECT'
GROUP BY s.grouping_name
ORDER BY total_effect DESC;

```

---
### **Graf 6: Weight vs Effect**

Táto vizualizácia zobrazuje  priame porovnanie váhy sektora a jeho výkonnostného efektu. Graf vizualizuje efektívnosť alokácie - či sektory s vyššou váhou prinášajú adekvátny výnos.

**Príklad kódu:**
```sql
SELECT ds.grouping_name AS sector,
    SUM(CASE WHEN dmt.measure_name = 'PORT_WEIGHT' THEN f.metric_value END) AS port_weight,
    SUM(CASE WHEN dmt.measure_name = 'TOTAL_EFFECT' THEN f.metric_value END) AS total_effect
FROM fact_portfolio_analytics f
JOIN dim_measure_type dmt ON f.measure_type_id = dmt.measure_type_id
JOIN dim_sector ds ON f.sector_id = ds.sector_id
GROUP BY ds.grouping_name;
```

---
### **Graf 7: Porovnanie sektorových váh portfólia a benchmarku**

Táto vizualižácia zobrazuje porovnanie váh sektorov v portfóliu a benchmarku. Graf identifikuje overweight sektory(portfólio > benchmark), underweight sektory (portfólio < benchmark), čo je kľúčové pre riadenie aktívneho rizika.

**Príklad kódu:**

```sql
SELECT ds.grouping_name as sector,
    SUM(CASE WHEN dmt.measure_name = 'PORT_WEIGHT' THEN f.metric_value END) AS portfolio_weight,
    SUM(CASE WHEN dmt.measure_name = 'BENCH_WEIGHT' THEN f.metric_value END) AS benchmark_weight
FROM fact_portfolio_analytics f
JOIN dim_measure_type dmt ON f.measure_type_id = dmt.measure_type_id
JOIN dim_sector ds ON f.sector_id = ds.sector_id
WHERE dmt.measure_name IN ('PORT_WEIGHT', 'BENCH_WEIGHT')
GROUP BY ds.grouping_name
ORDER BY ds.grouping_name;
```

---
**Autor:** Martin Ovcarčík, Alex Plaštiak
---
