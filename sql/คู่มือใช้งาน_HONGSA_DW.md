# คู่มือการใช้งาน HongsaDW - Star Schema Dimensional Model

## ภาพรวม

HongsaDW เป็น Data Warehouse ที่ออกแบบเป็น **Star Schema** สำหรับใช้งานกับ **SQL Server Analysis Services (SSAS) Tabular Data Model**

## ขั้นตอนการติดตั้ง

### 1. สร้าง Database และ Schema

```bash
sqlcmd -S <server_name> -i sql/create_hongsa_dw_schema.sql
```

หรือถ้าใช้ SQL Server Management Studio (SSMS):
1. เปิดไฟล์ `sql/create_hongsa_dw_schema.sql`
2. รันสคริปต์ทั้งหมด

สคริปต์นี้จะสร้าง:
- Database `HongsaDW`
- Dimension Tables: `DimHole`, `DimSeam`, `DimRock`, `DimDate`
- Fact Tables: `FactCoalAnalysis`, `FactLithology`
- Indexes และ Views

### 2. กำหนดค่าและ Populate ข้อมูล

**ขั้นตอนที่ 1**: แก้ไขชื่อ Source Database
- เปิดไฟล์ `sql/populate_hongsa_dw_data.sql`
- หา `DECLARE @SourceDbName NVARCHAR(100) = 'Hongsa';`
- เปลี่ยนเป็นชื่อ database ต้นทางของคุณ (เช่น `'Hongsa'`, `'HongsaDB'`, ฯลฯ)

**ขั้นตอนที่ 2**: รันสคริปต์ populate

```bash
sqlcmd -S <server_name> -d HongsaDW -i sql/populate_hongsa_dw_data.sql
```

หรือใช้ sqlcmd parameter:
```bash
sqlcmd -S <server_name> -d HongsaDW -i sql/populate_hongsa_dw_data.sql -v SourceDbName="ชื่อDatabaseต้นทาง"
```

**หมายเหตุสำคัญ**:
- ต้องมี Relational Database ต้นทางที่ populate ข้อมูลแล้ว
- Source Database ต้องอยู่ใน SQL Server instance เดียวกัน

## โครงสร้าง Star Schema

### Dimension Tables (ตารางมิติ)

| Table | คำอธิบาย | Key |
|-------|----------|-----|
| **DimHole** | ข้อมูลหลุมเจาะ | HoleKey (PK) |
| **DimSeam** | รหัสชั้นถ่านหิน | SeamKey (PK) |
| **DimRock** | ประเภทหิน/ลิโธโลยี | RockKey (PK) |
| **DimDate** | มิติเวลา | DateKey (PK), Format: YYYYMMDD |

### Fact Tables (ตารางข้อเท็จจริง)

| Table | คำอธิบาย | Measures |
|-------|----------|----------|
| **FactCoalAnalysis** | ผลการวิเคราะห์ถ่านหิน | Ash, VM, FC, GrossCV, NetCV, IM, TM, Sulphur, SG, RD, HGI |
| **FactLithology** | บันทึกลิโธโลยี | Thickness (DepthTo - DepthFrom) |

## การใช้งานกับ SSAS Tabular

### 1. สร้าง Tabular Model Project

1. เปิด **SQL Server Data Tools (SSDT)** หรือ **Visual Studio**
2. สร้าง Project ใหม่: **Analysis Services Tabular Project**
3. เลือก Workspace Database: **Tabular** (default 1400 compatibility level)

### 2. Import Data Source

1. ใน **Model Explorer** → คลิกขวาที่ **Data Sources** → **Import from Data Source**
2. เลือก **SQL Server**
3. ตั้งค่า Connection:
   - **Server**: ชื่อ SQL Server ของคุณ
   - **Database**: `HongsaDW`
4. เลือก **Impersonation**: **Service Account** หรือ **Windows Account**
5. เลือก Tables:
   - `DimHole`
   - `DimSeam`
   - `DimRock`
   - `DimDate`
   - `FactCoalAnalysis`
   - `FactLithology`

### 3. สร้าง Relationships

ใน **Model** → **Manage Relationships**, สร้าง relationships:

```
FactCoalAnalysis.HoleKey → DimHole.HoleKey
FactCoalAnalysis.SeamQualityKey → DimSeam.SeamKey
FactCoalAnalysis.Seam73Key → DimSeam.SeamKey
FactCoalAnalysis.AnalysisDateKey → DimDate.DateKey
FactLithology.HoleKey → DimHole.HoleKey
FactLithology.RockKey → DimRock.RockKey
FactLithology.LogDateKey → DimDate.DateKey
```

### 4. สร้าง Measures

ใน FactCoalAnalysis table, สร้าง Measures เช่น:

```DAX
Total Samples = COUNTROWS(FactCoalAnalysis)

Average Ash% = AVERAGE(FactCoalAnalysis[Ash])

Average GrossCV = AVERAGE(FactCoalAnalysis[GrossCV])

Total Thickness = SUM(FactCoalAnalysis[DepthThickness])
```

### 5. สร้าง Hierarchies

**DimDate Hierarchy**:
- Year → Quarter → Month → Day

**DimSeam Hierarchy**:
- SystemName → SeamLabel

**DimHole Hierarchy** (optional):
- Contractor → HoleID

### 6. Deploy Model

1. คลิกขวาที่ Project → **Properties**
2. ตั้งค่า **Server**: ชื่อ SSAS Server ของคุณ
3. ตั้งค่า **Database**: ชื่อที่ต้องการ (เช่น `HongsaDW_Tabular`)
4. **Build** Project
5. **Deploy** Project

## ตรวจสอบข้อมูล

หลังจาก populate ข้อมูลแล้ว สามารถตรวจสอบด้วย:

```sql
USE HongsaDW;

-- ดูจำนวนข้อมูลในแต่ละตาราง
SELECT 'DimDate' AS TableName, COUNT(*) AS RowCount FROM DimDate
UNION ALL SELECT 'DimHole', COUNT(*) FROM DimHole
UNION ALL SELECT 'DimSeam', COUNT(*) FROM DimSeam
UNION ALL SELECT 'DimRock', COUNT(*) FROM DimRock
UNION ALL SELECT 'FactCoalAnalysis', COUNT(*) FROM FactCoalAnalysis
UNION ALL SELECT 'FactLithology', COUNT(*) FROM FactLithology;

-- ตรวจสอบ Data Quality
SELECT 
    'FactCoalAnalysis with invalid HoleKey' AS CheckName,
    COUNT(*) AS IssueCount
FROM FactCoalAnalysis f
LEFT JOIN DimHole h ON f.HoleKey = h.HoleKey
WHERE h.HoleKey IS NULL;
```

## Views สำหรับ SSAS

Database มี Views พร้อมใช้:
- **vwCoalAnalysisCube**: Denormalized view สำหรับ FactCoalAnalysis
- **vwLithologyCube**: Denormalized view สำหรับ FactLithology

สามารถใช้ Views เหล่านี้แทน Tables โดยตรงใน SSAS ได้

## Troubleshooting

### ปัญหา: Source Database ไม่พบ

**แก้ไข**: 
- ตรวจสอบชื่อ database ใน `populate_hongsa_dw_data.sql`
- ตรวจสอบว่า database อยู่ใน SQL Server instance เดียวกัน
- ตรวจสอบ permissions

### ปัญหา: Foreign Key Violation

**แก้ไข**: 
- ตรวจสอบว่า populate Dimension tables ก่อน Fact tables
- ตรวจสอบว่า Source Database มีข้อมูลครบถ้วน

### ปัญหา: Date Dimension ไม่เพียงพอ

**แก้ไข**: 
- ปรับ range ใน `populate_hongsa_dw_data.sql` (ปัจจุบัน: 2000-2100)
- หรือเพิ่มช่วงปีตามต้องการ

## ไฟล์ที่เกี่ยวข้อง

- `sql/create_hongsa_dw_schema.sql` - สร้าง Schema
- `sql/populate_hongsa_dw_data.sql` - Populate ข้อมูล
- `sql/README_HONGSA_DW.md` - เอกสารภาษาอังกฤษ
- `sql/คู่มือใช้งาน_HONGSA_DW.md` - เอกสารนี้

## สรุป

HongsaDW พร้อมใช้งานกับ SSAS Tabular Model แล้ว! 

หลังจาก populate ข้อมูลและสร้าง Tabular Model แล้ว คุณสามารถ:
- สร้าง Reports ด้วย Power BI, Excel, หรือ SSRS
- ทำ Analytics และ Data Exploration
- สร้าง KPIs และ Measures ตามต้องการ

