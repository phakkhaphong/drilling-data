# SSAS Tabular Model Setup Guide สำหรับ HongsaDW

## ภาพรวม

คู่มือนี้จะแนะนำการสร้างและเชื่อมต่อ **SQL Server Analysis Services (SSAS) Tabular Model** กับ HongsaDW Star Schema

## Prerequisites

- SQL Server Data Tools (SSDT) หรือ Visual Studio 2019/2022
- SQL Server Analysis Services (SSAS) installed
- Access to HongsaDW database
- SQL Server instance running with HongsaDW database

## ขั้นตอนการ Setup

### 1. สร้าง Tabular Model Project

1. เปิด **Visual Studio** หรือ **SQL Server Data Tools**
2. คลิก **File** → **New** → **Project**
3. เลือก **Analysis Services** → **Analysis Services Tabular Project**
4. ตั้งชื่อ Project (เช่น `HongsaDW_Tabular`)
5. เลือก **Workspace Database**:
   - **Workspace Server**: ชื่อ SQL Server ของคุณ (เช่น `localhost` หรือ `35.240.189.135`)
   - **Compatibility Level**: เลือก **SQL Server 2019 / Azure Analysis Services (1500)** หรือใหม่กว่า

### 2. Import Data Source

1. ใน **Solution Explorer** → คลิกขวาที่ **Data Sources** → **Import from Data Source**
2. เลือก **SQL Server** → **Next**
3. ตั้งค่า Connection:
   ```
   Server: 35.240.189.135 (หรือชื่อ server ของคุณ)
   Database: HongsaDW
   Impersonation: Use a specific Windows user name and password
     หรือ Service Account (ขึ้นอยู่กับการตั้งค่า)
   ```
4. คลิก **Test Connection** เพื่อทดสอบ
5. คลิก **Finish**

### 3. Import Tables

1. ใน **Model** → **Table Import Wizard**
2. เลือก Tables ทั้งหมด:
   - ✅ **DimDate**
   - ✅ **DimHole**
   - ✅ **DimSeam**
   - ✅ **DimRock**
   - ✅ **FactCoalAnalysis**
   - ✅ **FactLithology**
3. คลิก **Finish** → รอให้ import เสร็จ

### 4. สร้าง Relationships

ใน **Model** → **Manage Relationships** (หรือคลิกขวาที่ table → Manage Relationships)

สร้าง Relationships ดังนี้:

```
FactCoalAnalysis[HoleKey] → DimHole[HoleKey]
  Cardinality: Many-to-One
  Filter Direction: Both

FactCoalAnalysis[SeamQualityKey] → DimSeam[SeamKey]
  Cardinality: Many-to-One
  Filter Direction: Both

FactCoalAnalysis[Seam73Key] → DimSeam[SeamKey]
  Cardinality: Many-to-One
  Filter Direction: Both

FactCoalAnalysis[AnalysisDateKey] → DimDate[DateKey]
  Cardinality: Many-to-One
  Filter Direction: Both

FactLithology[HoleKey] → DimHole[HoleKey]
  Cardinality: Many-to-One
  Filter Direction: Both

FactLithology[RockKey] → DimRock[RockKey]
  Cardinality: Many-to-One
  Filter Direction: Both

FactLithology[LogDateKey] → DimDate[DateKey]
  Cardinality: Many-to-One
  Filter Direction: Both
```

**หมายเหตุ**: 
- Ensure **Both** filter direction เพื่อให้สามารถ filter จาก Dimension ไปยัง Fact หรือจาก Fact ไปยัง Dimension ได้
- **Active** = True สำหรับทุก relationship

### 5. Mark Date Table

1. เลือก **DimDate** table
2. คลิกขวา → **Mark as Date Table**
3. เลือก **DateKey** เป็น Date Column
4. เลือก **FullDate** เป็น Date Value

### 6. สร้าง Hierarchies

#### DimDate Hierarchy

1. เลือก **DimDate** table
2. ใน **Fields** pane → คลิกขวาที่ **Year** → **Create Hierarchy**
3. ตั้งชื่อ: `Calendar Hierarchy`
4. ลาก Field ตามลำดับ:
   - Year
   - Quarter → QuarterName
   - Month → MonthName
   - Day

#### DimSeam Hierarchy

1. เลือก **DimSeam** table
2. สร้าง Hierarchy ชื่อ: `Seam System Hierarchy`
3. ลาก Field:
   - SystemName
   - SeamLabel

#### DimHole Hierarchy (Optional)

1. เลือก **DimHole** table
2. สร้าง Hierarchy ชื่อ: `Hole Hierarchy`
3. ลาก Field:
   - Contractor (ถ้ามี)
   - HoleID

### 7. สร้าง Measures

#### ใน FactCoalAnalysis Table

สร้าง Measures ต่อไปนี้:

**Total Samples**
```DAX
Total Samples = COUNTROWS(FactCoalAnalysis)
```

**Average Ash%**
```DAX
Average Ash% = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[Ash]),
    NOT(ISBLANK(FactCoalAnalysis[Ash]))
)
```

**Average Gross CV**
```DAX
Average Gross CV = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[GrossCV]),
    NOT(ISBLANK(FactCoalAnalysis[GrossCV]))
)
```

**Average Net CV**
```DAX
Average Net CV = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[NetCV]),
    NOT(ISBLANK(FactCoalAnalysis[NetCV]))
)
```

**Total Thickness**
```DAX
Total Thickness = SUM(FactCoalAnalysis[DepthThickness])
```

**Average VM%**
```DAX
Average VM% = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[VM]),
    NOT(ISBLANK(FactCoalAnalysis[VM]))
)
```

**Average FC%**
```DAX
Average FC% = 
CALCULATE(
    AVERAGE(FactCoalAnalysis[FC]),
    NOT(ISBLANK(FactCoalAnalysis[FC]))
)
```

#### ใน FactLithology Table

**Total Logs**
```DAX
Total Logs = COUNTROWS(FactLithology)
```

**Total Thickness**
```DAX
Total Lithology Thickness = SUM(FactLithology[Thickness])
```

### 8. Hide Columns ที่ไม่จำเป็น

Hide columns ที่เป็น surrogate keys และ internal IDs:

- DimHole: HoleKey
- DimSeam: SeamKey, SeamID
- DimRock: RockKey
- DimDate: DateKey
- FactCoalAnalysis: FactCoalAnalysisKey, HoleKey, SeamQualityKey, Seam73Key, AnalysisDateKey
- FactLithology: FactLithologyKey, HoleKey, RockKey, LogDateKey

**วิธี Hide**:
1. เลือก column
2. ใน Properties → **Is Hidden** = True

### 9. Format Columns

ตั้งค่า Format ให้เหมาะสม:

- **Ash, VM, FC, IM, TM, Sulphur**: Percentage (2 decimal places)
- **GrossCV, NetCV**: Number (0 decimal places, thousand separator)
- **SG, RD, HGI**: Number (2 decimal places)
- **DepthFrom, DepthTo, DepthThickness**: Number (2 decimal places)

**วิธี Format**:
1. เลือก column
2. ใน Properties → **Format** → เลือก format ที่ต้องการ

### 10. Deploy Model

1. คลิกขวาที่ Project → **Properties**
2. ใน **Deployment** tab:
   - **Server**: ชื่อ SSAS Server (เช่น `localhost` หรือ SSAS server name)
   - **Database**: ชื่อ database ที่ต้องการ (เช่น `HongsaDW_Tabular`)
3. **Build** Project (F6 หรือ Build → Build Solution)
4. **Deploy** Project (คลิกขวาที่ Project → Deploy)

## การใช้งานหลังจาก Deploy

### 1. เชื่อมต่อจาก Excel

1. เปิด Excel
2. **Data** → **Get Data** → **From Database** → **From Analysis Services Database**
3. ใส่ Server name และ Database name
4. เลือก Cube/Model
5. สร้าง PivotTable หรือ PivotChart

### 2. เชื่อมต่อจาก Power BI

1. เปิด Power BI Desktop
2. **Get Data** → **Database** → **SQL Server Analysis Services database**
3. เลือก **Connect live**
4. ใส่ Server และ Database
5. เลือก Model

### 3. เชื่อมต่อจาก SSRS

1. สร้าง Data Source ใหม่
2. เลือก **Microsoft SQL Server Analysis Services**
3. ใส่ Connection String
4. เลือก Model

## Best Practices

1. **Regular Refresh**: ตั้งค่า scheduled refresh สำหรับข้อมูลใหม่
2. **Partitioning**: สำหรับ Fact tables ที่มีข้อมูลมาก แบ่ง partition ตาม date
3. **Aggregations**: ใช้ aggregations สำหรับ performance ในข้อมูลขนาดใหญ่
4. **Security**: ตั้งค่า Row-Level Security (RLS) ถ้าต้องการจำกัดข้อมูลตาม user

## Troubleshooting

### Connection Issues
- ตรวจสอบว่า SSAS service ทำงานอยู่
- ตรวจสอบ firewall settings
- ตรวจสอบ permissions ของ user

### Data Refresh Issues
- ตรวจสอบว่า source database accessible
- ตรวจสอบ impersonation settings
- ตรวจสอบ error logs ใน SSAS

## Resources

- [SSAS Tabular Documentation](https://docs.microsoft.com/en-us/analysis-services/tabular-models/)
- [DAX Guide](https://dax.guide/)
- [Tabular Model Best Practices](https://docs.microsoft.com/en-us/analysis-services/tabular-models/best-practices)

---

**หมายเหตุ**: เอกสารนี้อ้างอิงจาก SQL Server 2019/Analysis Services 2019 และใหม่กว่า

