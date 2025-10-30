# SQL Server Import Guide

## ไฟล์ที่ต้องใช้

### SQL Scripts
- `sql/create_tables.sql` - สร้างตาราง
- `sql/add_foreign_keys.sql` - เพิ่ม Foreign Keys
- `sql/check_data.sql` - ตรวจสอบข้อมูล

### CSV Files (ใช้ไฟล์เหล่านี้เท่านั้น)
- `data/processed/collars.csv`
- `data/processed/rock_types.csv`
- `data/processed/seam_codes.csv` ⚠️ **ใช้ไฟล์นี้**
- `data/processed/lithology_logs.csv` ⚠️ **ใช้ไฟล์นี้**
- `data/processed/sample_analyses.csv` ⚠️ **ใช้ไฟล์นี้**

## ขั้นตอนการนำเข้าข้อมูล

### Step 1: สร้างตาราง
```sql
-- รันไฟล์ sql/create_tables.sql
```

### Step 2: นำเข้าข้อมูล CSV
ใช้ SQL Server Import Wizard ตามลำดับ:

1. **collars** → `collars.csv`
2. **rock_types** → `rock_types.csv`
3. **seam_codes** → `seam_codes.csv`
4. **lithology_logs** → `lithology_logs.csv`
5. **sample_analyses** → `sample_analyses.csv`

### Step 3: เพิ่ม Foreign Keys
```sql
-- รันไฟล์ sql/add_foreign_keys.sql
```

### Step 4: ตรวจสอบข้อมูล
```sql
-- รันไฟล์ sql/check_data.sql
```

## การตั้งค่า Import Wizard

### ตั้งค่าทั่วไป
- **Data Source**: Flat File Source
- **File Format**: Delimited
- **Locale**: English (United States)
- **Code page**: 1252 (ANSI)

### ตั้งค่า Delimiter
- **Row delimiter**: {CR}{LF}
- **Column delimiter**: Comma {,}
- **Text qualifier**: Double quote {"}

### ตั้งค่า Error Handling
- **Error**: Redirect row
- **Truncation**: Redirect row

## การตั้งค่าเฉพาะ SAMPLE_ANALYSES

### ไฟล์: `sample_analyses.csv`
- **Data Types**:
  - `sample_id`: Integer
  - `hole_id`: String (50)
  - `depth_from`: Float
  - `depth_to`: Float
  - `sample_no`: String (50)
  - `im`: Float
  - `tm`: Float
  - `ash`: Float
  - `vm`: Float
  - `fc`: Float
  - `sulphur`: Float
  - `gross_cv`: Float
  - `net_cv`: Float ⚠️ **ค่าว่างถูกแทนที่ด้วย 0.0**
  - `sg`: Float
  - `rd`: Float
  - `hgi`: Float
  - `seam_code_quality`: Integer
  - `seam_code_73`: Integer
  - `quality_seam_label`: String (100)
  - `seam_label_73`: String (100)

## ข้อแตกต่างของไฟล์ใหม่

### `sample_analyses.csv` vs ไฟล์เก่า
- **เก่า**: `net_cv` = `` (empty value) - มีปัญหา Data Conversion
- **ใหม่**: `net_cv` = `0.0` (zero value)
- **ผลลัพธ์**: SQL Server สามารถแปลง 0.0 เป็น FLOAT ได้โดยไม่มีปัญหา

## การแก้ไขปัญหา

### ✅ ปัญหาที่แก้ไขแล้ว:
1. **SEAM_CODES**: เพิ่มคอลัมน์ `seam_code_id`
2. **LITHOLOGY_LOGS**: แก้ไขอักขระพิเศษและตัดข้อความยาว
3. **SAMPLE_ANALYSES**: แก้ไข `net_cv` ให้เป็น `0.0` แทนค่าว่าง

### ⚠️ ข้อควรระวัง:
- ใช้ไฟล์ `sample_analyses.csv` เท่านั้น
- อย่าใช้ไฟล์อื่นๆ สำหรับ SAMPLE_ANALYSES
- ตั้งค่า Error Output เป็น "Redirect row"

## หมายเหตุ

- ไฟล์ `sample_analyses.csv` ใช้ `0.0` แทนค่าว่าง
- ไฟล์ `lithology_logs.csv` ได้แก้ไขอักขระพิเศษแล้ว
- ไฟล์ `seam_codes.csv` มีคอลัมน์ `seam_code_id` แล้ว
- ตรวจสอบว่าไฟล์ CSV มี header row
- ตั้งค่า Error Output เป็น "Redirect row" เพื่อไม่หยุดเมื่อมี error

## สรุป

ใช้ไฟล์ `sample_analyses.csv` สำหรับ SAMPLE_ANALYSES และควรจะไม่มีปัญหา Data Conversion อีกต่อไป!

**ไฟล์เหล่านี้ได้รับการแก้ไขและทดสอบแล้ว พร้อมใช้งาน!**

