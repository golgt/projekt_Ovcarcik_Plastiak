# **ELT proces datasetu FactSet Analytics (sample)**


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
  <img width="1333" height="1329" alt="ERD" src="https://github.com/user-attachments/assets/98b5f7e2-85f7-4551-98b8-e78a93c32fa6" />
  <br>
  <em>Obrázok 1 Entitno-relačná schéma FactSet Analytics</em>
</p>

---
## **2. Dimenzionálny model**
<img width="1073" height="714" alt="Star_scheme" src="https://github.com/user-attachments/assets/773ca867-9f16-41b9-9b7c-015b0f0f0def" />
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

