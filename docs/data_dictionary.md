# Data Dictionary — Ghana Polio DHIS2 Dataset

**File**: `data/Polio_DHIS2_Ghana_Districts.xlsx`  
**Sheet**: `DHIS2_Raw_Data`  
**Records**: 84 (3 districts × 28 quarters × 1 row each)  
**Period**: 2018Q1 – 2024Q4  

---

## Variables

| Column | Type | Example | Description |
|---|---|---|---|
| `Period` | String | `2021Q3` | DHIS2 standard quarter format: `YYYYQq` |
| `Year` | Integer | `2021` | Calendar year |
| `Quarter` | Integer | `3` | Quarter number (1–4) |
| `District` | String | `Accra Metro` | One of 3 study districts |
| `Region` | String | `Greater Accra` | Administrative region of district |
| `Target_Children` | Integer | `18540` | Surviving infants — the immunisation denominator |
| `OPV0_Doses` | Integer | `16200` | Birth-dose OPV administered (ideally within 14 days of birth) |
| `OPV1_Doses` | Integer | `15400` | First scheduled OPV dose |
| `OPV2_Doses` | Integer | `14800` | Second scheduled OPV dose |
| `OPV3_Doses` | Integer | `14100` | Third scheduled OPV dose — primary coverage indicator |
| `AFP_Cases` | Integer | `4` | Acute Flaccid Paralysis cases reported that quarter |
| `Zero_Dose_Children` | Integer | `1250` | Children who received zero OPV doses |

---

## Derived Variables (computed in R)

| Variable | Formula | Description |
|---|---|---|
| `OPV3_Coverage` | `OPV3_Doses / Target_Children` | Primary coverage indicator |
| `Dropout_OPV1_OPV3` | `(OPV1 - OPV3) / OPV1` | Proportion dropping out after dose 1 |
| `Dropout_OPV1_OPV2` | `(OPV1 - OPV2) / OPV1` | Proportion dropping out after dose 1 (earlier) |
| `Zero_Dose_Rate` | `Zero_Dose_Children / Target_Children` | Fraction of target unimmunised |
| `AFP_MA3` | 3-period rolling mean | Smoothed AFP surveillance signal |
| `OPV3_Coverage_MA` | 3-period rolling mean | Smoothed coverage trend |
| `Time` | Row index per district | Numeric covariate for regression models |

---

## Districts

| District | Region | Population Tier |
|---|---|---|
| Accra Metro | Greater Accra | High (urban, large) |
| Kumasi Metro | Ashanti | High (urban, large) |
| Tamale Metro | Northern | Medium (urban, lower baseline coverage) |

---

## Notes

- Data is **simulated** to reflect realistic Ghana immunisation programme patterns
- Replace with real DHIS2 exports for production analysis
- AFP cases follow WHO surveillance protocol: ≥ 1 case per 100,000 children < 15 years is the sensitivity target
- Zero-dose children are a WHO/UNICEF priority indicator for equity analysis
- The 80% OPV3 coverage threshold is the WHO Global Polio Eradication Initiative minimum target
