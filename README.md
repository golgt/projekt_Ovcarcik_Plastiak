ELT proces datasetu FactSet Analytics (sample)

1. Úvod a popis zdrojových dát
V tomto projekte analyzujeme dáta o finančných portfóliách, ktoré obsahujú podrobné informácie o účtoch, cenných papieroch a ich výkonnosti v čase. Databáza obsahuje rôzne zdrojové tabuľky, ktoré umožňujú komplexnú analýzu portfólií a benchmarkov. Cieľom je porozumieť:
-ako sa váhy a zloženie portfólia menia v čase a voči benchmarku
-ktoré sektory a cenné papiere prispievajú najviac k výnosu portfólia
-vplyvu alokačných, selekčných a menových efektov na celkový výnos
-rizikovým profilom portfólia a jeho citlivosti na trhové zmeny

Zdrojové dáta pochádzajú z Snowflake datasetu dostupného tu. Na náš projekt sme si vybrali FactSet Analytics (sample) dataset ktorý obsahuje tabuľky:

CHARACTERISTICS – Tabuľka, ktorá uchováva finančné údaje na úrovni účtu alebo portfólia
EQ_SECTOR_ATTRIBUTION – Tabuľka pre equity sektorovú atribučnú analýzu, ktorá porovnáva výkonnosť portfólia a benchmarku
EQ_SECTOR_EXPOSURES – Tabuľka, ktorá zobrazuje expozície akciového portfólia voči jednotlivým sektorom alebo cenným papierom v porovnaní s benchmarkom
FI_SECTOR_ATTRIBUTION – Tabuľka pre atribučnú analýzu výkonnosti dlhopisového portfólia
FI_SECTOR_EXPOSURESN – Tabuľka, ktorá zobrazuje sektorové expozície dlhopisového
HOLDINGS – Tabuľka s detailnými informáciami o jednotlivých pozíciách v portfóliu a benchmarku
METADATA_WEIGHTS_EXAMPLE – ukážková Tabuľka, ktorá porovnáva váhy portfólia a benchmarku podľa skupín alebo cenných papierov a zobrazuje ich rozdiely v čase spolu s identifikačnými a hierarchickými údajmi
PA_METADATA – Tabuľka, ktorá popisuje nastavenia, identitu a časový rozsah portfólia a reportov používaných v analytických výpočtoch.
RETURNS – Tabuľka, ktorá uchováva výnosy portfólia a jeho benchmarku za jednotlivé obdobia, vrátane dátumu výpočtu, frekvencie výnosov a meny portfólia.

Účelom ELT procesu je tieto dáta pripraviť, transformovať, a sprístupniť pre viacdimenzionálnu analýzu.

1.1 Dátová architektúra
ERD diagram
<img width="1333" height="1329" alt="ERD" src="https://github.com/user-attachments/assets/98b5f7e2-85f7-4551-98b8-e78a93c32fa6" />

Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame (ERD):
2. Dimenzionálny model

