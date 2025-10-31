# HongsaDW - Dimensional Model (Star Schema)

## ภาพรวม

HongsaDW เป็น Dimensional Data Warehouse ที่ออกแบบตาม Star Schema สำหรับใช้กับ **SQL Server Analysis Services (SSAS) Tabular Data Model**

โครงสร้างนี้แปลงจาก Relational Model (3NF) เดิมมาเป็น Star Schema เพื่อ:
- สะดวกต่อการสร้าง Data Model ใน SSAS Tabular
- เพิ่มประสิทธิภาพการ Query ข้อมูล
- รองรับการทำ Analytics และ Reporting

## โครงสร้างฐานข้อมูล

### Dimension Tables (ตารางมิติ)

#### 1. DimHole
ตารางมิติสำหรับข้อมูลหลุมเจาะ
- **HoleKey**: Surrogate Key (Primary Key)
- **HoleID**: Business Key (Unique)
- **Location Attributes**: Easting, Northing, Elevation
- **Drilling Attributes**: Azimuth, Dip, FinalDepth, Contractor
- **Time Attributes**: DrillingDateKey (FK to DimDate), DrillingYear, DrillingMonth, DrillingQuarter

#### 2. DimSeam
ตารางมิติสำหรับรหัสชั้นถ่านหิน
- **SeamKey**: Surrogate Key (Primary Key)
- **SeamID**: Original seam_id from relational model
- **Seam Attributes**: SystemID, SystemName, SeamLabel, SeamCode, Priority
- **SystemHierarchy**: สำหรับสร้าง Hierarchy ใน SSAS (e.g., "Quality > H3c")

#### 3. DimRock
ตารางมิติสำหรับประเภทหิน/ลิโธโลยี
- **RockKey**: Surrogate Key (Primary Key)
- **RockCode**: Original rock_code
- **Rock Attributes**: Lithology, Detail, RockCategory

#### 4. DimDate
ตารางมิติสำหรับเวลา (Time Dimension)
- **DateKey**: Primary Key (Format: YYYYMMDD)
- **FullDate**: Full date value
- **Time Attributes**: Day, Month, MonthName, Quarter, Year, etc.
- **Calendar Attributes**: WeekOfYear, DayOfWeek, IsWeekend, IsHoliday

### Fact Tables (ตารางข้อเท็จจริง)

#### 1. FactCoalAnalysis
ตารางข้อเท็จจริงหลักสำหรับผลการวิเคราะห์ตัวอย่างถ่านหิน

**Dimension Keys:**
- **HoleKey** (FK to DimHole)
- **SeamQualityKey** (FK to DimSeam) - Primary seam classification
- **Seam73Key** (FK to DimSeam) - Secondary seam classification
- **AnalysisDateKey** (FK to DimDate)

**Measures:**
- **Proximate Analysis**: IM (%), TM (%), Ash (%), VM (%), FC (%)
- **Ultimate Analysis**: Sulphur (%)
- **Calorific Value**: GrossCV (kcal/kg), NetCV (kcal/kg)
- **Physical Properties**: SG, RD, HGI
- **Calculated Measure**: DepthThickness = DepthTo - DepthFrom

#### 2. FactLithology
ตารางข้อเท็จจริงสำหรับบันทึกลิโธโลยี

**Dimension Keys:**
- **HoleKey** (FK to DimHole)
- **RockKey** (FK to DimRock)
- **LogDateKey** (FK to DimDate)

**Measures:**
- **Thickness**: Calculated measure (DepthTo - DepthFrom)

## การใช้งาน

### 1. สร้าง Schema

```bash
sqlcmd -S <server> -d master -i sql/create_hongsa_dw_schema.sql
```

สคริปต์นี้จะ:
- สร้าง database `HongsaDW`
- สร้าง Dimension Tables ทั้งหมด
- สร้าง Fact Tables ทั้งหมด
- สร้าง Indexes สำหรับประสิทธิภาพ
- สร้าง Views สำหรับ SSAS Tabular (`vwCoalAnalysisCube`, `vwLithologyCube`)

### 2. Populate Data

```bash
sqlcmd -S <server> -d HongsaDW -i sql/populate_hongsa_dw_data.sql
```

**หมายเหตุ**: ก่อนรันสคริปต์นี้:
1. ต้องมี Relational Database ต้นทางที่มีข้อมูลแล้ว (เช่น database `Hongsa`)
2. แก้ไขค่า `@SourceDbName` ในสคริปต์ให้ตรงกับชื่อ database ต้นทาง

สคริปต์นี้จะ:
- สร้าง DimDate สำหรับช่วงปี 2000-2100
- ดึงข้อมูล Dimension จาก database ต้นทาง
- ดึงข้อมูล Fact จาก database ต้นทางและ join กับ Dimension Keys
- ตรวจสอบ Data Quality

### 3. เชื่อมต่อกับ SSAS Tabular

1. เปิด SQL Server Data Tools (SSDT) หรือ Visual Studio
2. สร้าง Tabular Model Project ใหม่
3. Import Data Source:
   - Connection String: SQL Server database `HongsaDW`
   - Data Source Views: เลือก Fact และ Dimension tables
4. สร้าง Relationships:
   - FactCoalAnalysis → DimHole (HoleKey)
   - FactCoalAnalysis → DimSeam (SeamQualityKey, Seam73Key)
   - FactCoalAnalysis → DimDate (AnalysisDateKey)
   - FactLithology → DimHole (HoleKey)
   - FactLithology → DimRock (RockKey)
   - FactLithology → DimDate (LogDateKey)
5. สร้าง Measures และ Calculated Columns ตามต้องการ
6. Deploy Model ไปยัง SSAS Server

## Views สำหรับ SSAS

### vwCoalAnalysisCube
View ที่ denormalize ข้อมูล FactCoalAnalysis พร้อม Dimension attributes สำหรับ SSAS Tabular

### vwLithologyCube
View ที่ denormalize ข้อมูล FactLithology พร้อม Dimension attributes สำหรับ SSAS Tabular

## Best Practices

1. **Surrogate Keys**: ใช้ INTEGER IDENTITY สำหรับทุก Dimension และ Fact tables
2. **Business Keys**: เก็บ Business Keys (HoleID, SeamID, etc.) สำหรับ reference
3. **Calculated Columns**: ใช้ PERSISTED columns สำหรับ calculated measures
4. **Indexes**: สร้าง indexes บน Foreign Keys และ frequently queried columns
5. **Data Quality**: ตรวจสอบ orphaned records และ data integrity

## Data Model Diagram

```
                    DimDate
                       ↑
                       │
         ┌─────────────┼─────────────┐
         │             │             │
    FactCoalAnalysis  FactLithology  DimHole
         │             │
         ├─────────────┤
         │             │
      DimSeam       DimRock
```

## ติดต่อ

สำหรับคำถามหรือปัญหาเกี่ยวกับ HongsaDW schema กรุณาตรวจสอบ:
- SQL scripts ในโฟลเดอร์ `sql/`
- Documentation ในโฟลเดอร์ `docs/`

