# DAX Queries ตัวอย่างสำหรับ HongsaDW Tabular Model

## ภาพรวม

เอกสารนี้รวบรวม DAX Queries ตัวอย่างสำหรับใช้กับ HongsaDW Tabular Model ใน SSAS

## Measures พื้นฐาน

### FactCoalAnalysis Measures

```dax
// Total Samples
Total Samples = COUNTROWS(FactCoalAnalysis)

// Average Ash Content
Average Ash% = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[Ash]),
    NOT(ISBLANK(FactCoalAnalysis[Ash]))
)

// Average Gross Calorific Value
Average Gross CV = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[GrossCV]),
    NOT(ISBLANK(FactCoalAnalysis[GrossCV]))
)

// Average Net Calorific Value
Average Net CV = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[NetCV]),
    NOT(ISBLANK(FactCoalAnalysis[NetCV]))
)

// Total Thickness (Sum of Depth Intervals)
Total Thickness = SUM(FactCoalAnalysis[DepthThickness])

// Weighted Average Ash (weighted by thickness)
Weighted Average Ash% = 
VAR TotalWeight = SUM(FactCoalAnalysis[DepthThickness])
VAR WeightedSum = SUMX(
    FactCoalAnalysis,
    FactCoalAnalysis[Ash] * FactCoalAnalysis[DepthThickness]
)
RETURN
IF(TotalWeight > 0, WeightedSum / TotalWeight, BLANK())
```

## Measures ที่ใช้ CALCULATE และ FILTER

```dax
// Samples with High Quality (Ash < 10%)
High Quality Samples = 
CALCULATE(
    COUNTROWS(FactCoalAnalysis),
    FactCoalAnalysis[Ash] < 10
)

// Average CV for High Quality Coal
High Quality Average CV = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[GrossCV]),
    FactCoalAnalysis[Ash] < 10,
    NOT(ISBLANK(FactCoalAnalysis[GrossCV]))
)

// Samples by Seam Quality System
Samples by Quality System = 
CALCULATE(
    COUNTROWS(FactCoalAnalysis),
    NOT(ISBLANK(FactCoalAnalysis[SeamQualityKey]))
)

// Samples by System 73
Samples by System 73 = 
CALCULATE(
    COUNTROWS(FactCoalAnalysis),
    NOT(ISBLANK(FactCoalAnalysis[Seam73Key]))
)
```

## Time Intelligence Measures

```dax
// Samples This Year
Samples This Year = 
CALCULATE(
    COUNTROWS(FactCoalAnalysis),
    FILTER(
        ALL(DimDate[Year]),
        DimDate[Year] = YEAR(TODAY())
    )
)

// Average CV Year over Year
Average CV YOY = 
VAR CurrentYear = YEAR(TODAY())
VAR PreviousYear = CurrentYear - 1
VAR CurrentAvg = 
    CALCULATE(
        AVERAGE(FactCoalAnalysis[GrossCV]),
        DimDate[Year] = CurrentYear
    )
VAR PreviousAvg = 
    CALCULATE(
        AVERAGE(FactCoalAnalysis[GrossCV]),
        DimDate[Year] = PreviousYear
    )
RETURN
IF(
    NOT(ISBLANK(CurrentAvg)) && NOT(ISBLANK(PreviousAvg)),
    CurrentAvg - PreviousAvg,
    BLANK()
)

// Samples by Quarter
Samples by Quarter = 
COUNTROWS(FactCoalAnalysis)
```

## Measures แบบ Conditional

```dax
// Quality Category
Quality Category = 
SWITCH(
    TRUE(),
    AVERAGE(FactCoalAnalysis[Ash]) < 10, "Premium",
    AVERAGE(FactCoalAnalysis[Ash]) < 15, "High Quality",
    AVERAGE(FactCoalAnalysis[Ash]) < 25, "Standard",
    "Low Quality"
)

// Coal Type by Fixed Carbon
Coal Type = 
SWITCH(
    TRUE(),
    AVERAGE(FactCoalAnalysis[FC]) >= 90, "Anthracite",
    AVERAGE(FactCoalAnalysis[FC]) >= 80, "Bituminous",
    AVERAGE(FactCoalAnalysis[FC]) >= 60, "Sub-bituminous",
    "Lignite"
)
```

## Measures สำหรับ FactLithology

```dax
// Total Lithology Logs
Total Logs = COUNTROWS(FactLithology)

// Total Lithology Thickness
Total Lithology Thickness = SUM(FactLithology[Thickness])

// Coal Layer Thickness
Coal Layer Thickness = 
CALCULATE(
    SUM(FactLithology[Thickness]),
    DimRock[RockCategory] = "Coal"
)

// Average Log Thickness by Rock Type
Average Log Thickness = AVERAGE(FactLithology[Thickness])
```

## Calculated Columns

```dax
// ใน DimHole: Full Hole Description
Full Hole Description = 
DimHole[HoleID] & " - " & 
IF(
    NOT(ISBLANK(DimHole[Contractor])),
    DimHole[Contractor],
    "Unknown Contractor"
)

// ใน DimSeam: Full Seam Code
Full Seam Code = 
DimSeam[SystemName] & " - " & DimSeam[SeamLabel]

// ใน FactCoalAnalysis: Sample Quality Score
Quality Score = 
SWITCH(
    TRUE(),
    FactCoalAnalysis[Ash] < 10, 100,
    FactCoalAnalysis[Ash] < 15, 80,
    FactCoalAnalysis[Ash] < 25, 60,
    40
)
```

## Advanced Measures

```dax
// Top 10 Holes by Sample Count
Top 10 Holes = 
TOPN(
    10,
    SUMMARIZE(
        FactCoalAnalysis,
        DimHole[HoleID],
        "SampleCount", COUNTROWS(FactCoalAnalysis)
    ),
    [SampleCount],
    DESC
)

// Correlation between Ash and CV
Ash CV Correlation = 
VAR SamplesWithBoth = 
    FILTER(
        FactCoalAnalysis,
        NOT(ISBLANK(FactCoalAnalysis[Ash])) &&
        NOT(ISBLANK(FactCoalAnalysis[GrossCV]))
    )
RETURN
// This would require statistical functions
// Placeholder for correlation calculation
COUNTROWS(SamplesWithBoth)

// Running Total of Samples by Date
Running Total Samples = 
CALCULATE(
    COUNTROWS(FactCoalAnalysis),
    FILTER(
        ALL(DimDate[FullDate]),
        DimDate[FullDate] <= MAX(DimDate[FullDate])
    )
)
```

## KPI Measures

```dax
// Target Average CV (example: 5000 kcal/kg)
Target Average CV = 5000

// CV vs Target
CV vs Target = 
[Average Gross CV] - [Target Average CV]

// CV Achievement %
CV Achievement% = 
IF(
    [Target Average CV] > 0,
    [Average Gross CV] / [Target Average CV],
    BLANK()
)
```

## Usage Examples

### ใน Excel PivotTable

1. Drag **DimHole[HoleID]** ไป Rows
2. Drag **Average Ash%** ไป Values
3. Drag **Average Gross CV** ไป Values
4. Filter by **DimSeam[SystemName]**

### ใน Power BI

1. สร้าง **Matrix Visual**
2. Rows: **DimSeam[SystemName]**, **DimSeam[SeamLabel]**
3. Values: **Total Samples**, **Average Ash%**, **Average Gross CV**
4. Add **Slicer** for **DimDate[Year]**

### ใน DAX Query (MDX)

```dax
EVALUATE
SUMMARIZE(
    FactCoalAnalysis,
    DimHole[HoleID],
    DimSeam[SeamLabel],
    "SampleCount", COUNTROWS(FactCoalAnalysis),
    "AvgAsh", AVERAGE(FactCoalAnalysis[Ash]),
    "AvgCV", AVERAGE(FactCoalAnalysis[GrossCV])
)
```

## Performance Tips

1. **ใช้ SUM แทน SUMX** เมื่อเป็นไปได้
2. **ใช้ FILTER กับ ALL()** สำหรับ time intelligence
3. **หลีกเลี่ยง IF ในลูป** ใช้ SWITCH แทน
4. **ใช้ CALCULATE อย่างระมัดระวัง** - อาจช้าในข้อมูลมาก

---

**หมายเหตุ**: DAX queries เหล่านี้เป็นตัวอย่าง อาจต้องปรับแต่งตามความต้องการเฉพาะ

