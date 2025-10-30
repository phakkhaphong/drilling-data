# Project Structure - Hongsa Drilling Database

## Overview
โปรเจกต์นี้เป็นระบบจัดการข้อมูลการเจาะสำรวจเหมืองถ่านหิน (Diamond Core Drilling) ที่นำข้อมูลจากไฟล์ Excel มาทำความสะอาดและจัดเก็บในฐานข้อมูล SQLite

## ไฟล์หลัก (Core Files)

### 1. Data Processing Scripts
- **`src/data_processing/clean_and_create_db.py`** - สคริปต์หลักสำหรับทำความสะอาดข้อมูลจาก Excel และสร้างฐานข้อมูล SQLite
- **`src/data_processing/export_sqlite_to_csv.py`** - ส่งออกข้อมูลจาก SQLite เป็นไฟล์ CSV สำหรับนำเข้า SQL Server
- **`src/data_processing/validate_database.py`** - ตรวจสอบความถูกต้องและความสมบูรณ์ของข้อมูล

### 2. Database Files
- **`drilling_database.db`** - ฐานข้อมูล SQLite หลัก
- **`data/raw/DH70.xlsx`** - ไฟล์ข้อมูลดิบ (Excel)

### 3. Export Files (data/processed/)
- **`data/processed/collars.csv`** - ข้อมูลหลุมเจาะ (70 records)
- **`data/processed/lithology_logs.csv`** - บันทึกลำดับชั้นหิน (6,598 records)
- **`data/processed/sample_analyses.csv`** - ผลการวิเคราะห์ตัวอย่าง (8,592 records)
- **`data/processed/rock_types.csv`** - ประเภทหิน (19 records)
- **`data/processed/seam_codes.csv`** - รหัสชั้นถ่านหิน (97 records)
- **`data/processed/README.md`** - คำแนะนำการใช้งานไฟล์ CSV

### 4. SQL Query Files
- **`sample_sql_queries.sql`** - คำสั่ง SQL ตัวอย่าง 15 คำสั่ง สำหรับการสอบถามข้อมูล

### 5. Documentation
- **`README.md`** - คู่มือการใช้งานโปรเจกต์
- **`docs/PROJECT_STRUCTURE.md`** - ไฟล์นี้ (อธิบายโครงสร้างโปรเจกต์)
- **`docs/Data_Cleaning_Steps.md`** - ขั้นตอนการทำความสะอาดข้อมูล
- **`docs/SQL_SERVER_IMPORT_GUIDE.md`** - คู่มือการนำเข้าข้อมูลไปยัง SQL Server
- **`Data_Cleaning_Tutorial_Pandas.ipynb`** - Jupyter Notebook สอนการทำความสะอาดข้อมูลด้วย Pandas

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

1. **Data Normalization**
   ```bash
   python create_proper_normalized_database.py
   ```
   - อ่านข้อมูลจาก data/raw/DH70.xlsx
   - ทำความสะอาดและจัดหมวดหมู่ข้อมูล
   - สร้างฐานข้อมูลที่ normalized สำหรับ SQL Server

2. **Create SQL Server Database**
   ```bash
   sqlcmd -S your_server -d your_database -i sql/create_sql_server_schema.sql
   ```
   - สร้างตารางใน SQL Server
   - ตั้งค่า Foreign Keys และ Indexes

3. **Load Data to SQL Server**
   ```bash
   sqlcmd -S your_server -d your_database -i sql/load_sql_server_data.sql
   ```
   - โหลดข้อมูลจาก CSV files
   - ตรวจสอบความถูกต้องของข้อมูล

4. **Verify Database** (Manual)
   - ตรวจสอบข้อมูลใน SQL Server
   - ตรวจสอบความสัมพันธ์ระหว่างตาราง
   - ดูรายละเอียดใน docs/BEST_PRACTICES.md

## Dependencies

ดูที่ `requirements.txt`:
- **openpyxl** - อ่านไฟล์ Excel
- **pandas** - ประมวลผลข้อมูล
- **sqlite3** - จัดการฐานข้อมูล SQLite (built-in)

## Notes

- โปรเจกต์นี้ใช้ **Pandas** สำหรับการประมวลผลข้อมูล
- ข้อมูลถูกส่งออกเป็น CSV เท่านั้น ผู้ใช้ต้องนำเข้าข้อมูลไปยัง SQL Server เอง
- ชื่อตารางและคอลัมน์ใช้ **snake_case** ตาม ER diagram



