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

Exhtrahovanie (Extract) dáta sa získavajú z rôznych zdrojov ako napríklad databázy, súbory, rôzne datasety...
Keďže náš zdroj je Snowflake marketplace tak sme museli v marketplace dať „subscribe“ na dataset aby sme mohli s databázou pracovať. Následne sa vytvoril secure share dát čo znamená že dáta máme logicky dostupné, ale fyzicky ostali u poskytovaťeľa v tomto prípade FactSet.
Ako ďalší krok sme si vytvorili staging tabuľky do ktorých sme načítali dáta z datasetu FactSet Analytics.

**Príklad kódu:**
```sql
CREATE OR REPLACE TABLE table_staging AS
SELECT * FROM marketplace_db.schema.source_table;
```

