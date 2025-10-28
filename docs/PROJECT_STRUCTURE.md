# Project Structure - Hongsa Drilling Database

## Overview
โปรเจกต์นี้เป็นระบบจัดการข้อมูลการเจาะสำรวจเหมืองถ่านหิน (Diamond Core Drilling) ที่นำข้อมูลจากไฟล์ Excel มาทำความสะอาดและจัดเก็บในฐานข้อมูล SQLite

## ไฟล์หลัก (Core Files)

### 1. Data Processing Scripts
- **`clean_and_create_db.py`** - สคริปต์หลักสำหรับทำความสะอาดข้อมูลจาก Excel และสร้างฐานข้อมูล SQLite
- **`export_sqlite_to_csv.py`** - ส่งออกข้อมูลจาก SQLite เป็นไฟล์ CSV สำหรับนำเข้า SQL Server
- **`validate_database.py`** - ตรวจสอบความถูกต้องและความสมบูรณ์ของข้อมูล

### 2. Database Files
- **`drilling_database.db`** - ฐานข้อมูล SQLite หลัก
- **`DH70.xlsx`** - ไฟล์ข้อมูลดิบ (Excel)

### 3. Export Files (csv_export/)
- **`collars.csv`** - ข้อมูลหลุมเจาะ (70 records)
- **`lithology_logs.csv`** - บันทึกลำดับชั้นหิน (6,598 records)
- **`sample_analyses.csv`** - ผลการวิเคราะห์ตัวอย่าง (8,592 records)
- **`rock_types.csv`** - ประเภทหิน (19 records)
- **`seam_codes.csv`** - รหัสชั้นถ่านหิน (97 records)
- **`import_to_sqlserver.sql`** - สคริปต์ SQL สำหรับนำเข้าข้อมูลไปยัง SQL Server
- **`export_summary.txt`** - สรุปการส่งออกข้อมูล

### 4. SQL Query Files
- **`sample_sql_queries.sql`** - คำสั่ง SQL ตัวอย่าง 15 คำสั่ง สำหรับการสอบถามข้อมูล

### 5. Documentation
- **`README.md`** - คู่มือการใช้งานโปรเจกต์
- **`PROJECT_STRUCTURE.md`** - ไฟล์นี้ (อธิบายโครงสร้างโปรเจกต์)
- **`Data_Cleaning_Steps.md`** - ขั้นตอนการทำความสะอาดข้อมูล
- **`SQLite_Usage_Guide.md`** - คู่มือการใช้งาน SQLite
- **`SQL_Server_Import_Guide.md`** - คู่มือการนำเข้าข้อมูลไปยัง SQL Server
- **`SQLite_to_SQLServer_Migration.md`** - คู่มือการย้ายข้อมูลจาก SQLite ไป SQL Server

## Database Schema

### Tables
1. **`collars`** - ข้อมูลหลุมเจาะ (Primary table)
   - hole_id (PK), easting, northing, elevation, total_depth, inclination, year_drilled, geologist, block_no, dh_version
   
2. **`lithology_logs`** - บันทึกลำดับชั้นหิน
   - log_id (PK), hole_id (FK), depth_from, depth_to, thickness, rock_code (FK), description, clay_color, remark
   
3. **`sample_analyses`** - ผลการวิเคราะห์ตัวอย่าง
   - sample_id (PK), hole_id (FK), depth_from, depth_to, sample_no, im, tm, ash, vm, fc, sulphur, gross_cv, net_cv, sg, rd, hgi, seam_code_quality, seam_code_73, quality_seam_label, seam_label_73
   
4. **`rock_types`** - ประเภทหิน (Lookup table)
   - rock_code (PK), rock_name, rock_id
   
5. **`seam_codes`** - รหัสชั้นถ่านหิน (Lookup table)
   - seam_code (PK), seam_label, seam_system

### Relationships
- collars (1) ──> (N) lithology_logs
- collars (1) ──> (N) sample_analyses
- rock_types (1) ──> (N) lithology_logs
- seam_codes (1) ──> (N) sample_analyses

## Workflow

1. **Data Cleaning**
   ```bash
   python clean_and_create_db.py
   ```
   - อ่านข้อมูลจาก DH70.xlsx
   - ทำความสะอาดและจัดหมวดหมู่ข้อมูล
   - สร้างฐานข้อมูล SQLite

2. **Validate Database**
   ```bash
   python validate_database.py
   ```
   - ตรวจสอบความถูกต้องของข้อมูล
   - ตรวจสอบความสัมพันธ์ระหว่างตาราง

3. **Export to CSV**
   ```bash
   python export_sqlite_to_csv.py
   ```
   - ส่งออกข้อมูลเป็นไฟล์ CSV
   - สร้าง SQL import script

4. **Import to SQL Server** (Manual)
   - ใช้ไฟล์ CSV และ import_to_sqlserver.sql
   - ดูรายละเอียดใน SQL_Server_Import_Guide.md

## Dependencies

ดูที่ `requirements.txt`:
- **openpyxl** - อ่านไฟล์ Excel
- **polars** - ประมวลผลข้อมูล (แทน pandas)
- **sqlite3** - จัดการฐานข้อมูล SQLite (built-in)

## Notes

- โปรเจกต์นี้ใช้ **Polars** แทน Pandas เพื่อแก้ปัญหาการติดตั้งบน Windows ARM64
- ข้อมูลถูกส่งออกเป็น CSV เท่านั้น ผู้ใช้ต้องนำเข้าข้อมูลไปยัง SQL Server เอง
- ชื่อตารางและคอลัมน์ใช้ **snake_case** ตาม ER diagram



