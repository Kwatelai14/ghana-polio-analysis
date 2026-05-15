# Excel Analysis Guide — Ghana Polio DHIS2 Data

Open `data/Polio_DHIS2_Ghana_Districts.xlsx` in Microsoft Excel or LibreOffice Calc.

---

## Workbook Sheets

| Sheet | Contents |
|---|---|
| **DHIS2_Raw_Data** | 84 records — quarterly data for 3 districts, 2018–2024 |
| **Coverage_Trends** | OPV3 coverage rates with colour coding and line chart |
| **AFP_Surveillance** | AFP case counts with bar chart per district |
| **Zero_Dose_Children** | Zero-dose children tracker |

---

## Working with the Raw Data Sheet

### Add a Coverage Rate Column
In the first empty column after `Zero_Dose_Children`, add a header `OPV3_Coverage` and enter:
```
=H2/G2
```
Format the column as **Percentage (1 decimal place)**.

### Add a Dropout Rate Column
```
=E2-H2/E2
```
(OPV1 minus OPV3, divided by OPV1)

### Add a Zero-Dose Rate Column
```
=L2/G2
```

---

## Creating a District Filter View

1. Click any cell in the data
2. **Data → Filter → AutoFilter**
3. Use the **District** dropdown to filter to one district at a time

---

## Pivot Table — Coverage by District and Year

1. Click in the data range
2. **Insert → PivotTable** (place in new sheet)
3. Drag fields:
   - **Rows**: Year, Quarter
   - **Columns**: District
   - **Values**: OPV3_Doses (Sum), then add Target_Children (Sum)
4. Add a calculated field for coverage: `= OPV3_Doses / Target_Children`

---

## Conditional Formatting — Coverage Rates

Select your coverage rate column, then:

1. **Home → Conditional Formatting → Color Scales**
2. Or use **New Rule → Format cells based on value**:
   - ≥ 80% → Green fill (`#C6EFCE`)
   - 70–79% → Amber fill (`#FFEB9C`)
   - < 70% → Red fill (`#FFC7CE`)

This is already applied in the **Coverage_Trends** sheet.

---

## Adding a Trendline to a Chart

1. Click the chart line for a district
2. Right-click → **Add Trendline**
3. Choose **Linear**
4. Check **Display R-squared value on chart**

---

## Key Formulas Reference

| Formula | Purpose |
|---|---|
| `=AVERAGEIF($D$2:$D$85,D2,$H$2:$H$85)` | Average OPV3 for a district |
| `=COUNTIFS($D$2:$D$85,D2,$K$2:$K$85,">"&0)` | Count quarters with AFP cases |
| `=MAXIFS($H$2:$H$85/G$2:$G$85,$D$2:$D$85,D2)` | Highest coverage for a district |
| `=MINIFS($H$2:$H$85/G$2:$G$85,$D$2:$D$85,D2)` | Lowest coverage for a district |

---

## Exporting from DHIS2

To replace the sample data with real DHIS2 data:

1. Log in to your DHIS2 instance
2. Go to **Apps → Data Visualizer** or **Reports → Data Set Report**
3. Select:
   - **Organisation units**: Accra Metro, Kumasi Metro, Tamale Metro
   - **Data elements**: OPV0–3 doses, AFP cases, Target population
   - **Period**: Quarterly, 2018–2024
4. Click **Download → Excel (.xlsx)**
5. Copy the exported rows into the `DHIS2_Raw_Data` sheet, matching column names exactly
