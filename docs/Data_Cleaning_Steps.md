# 📋 ขั้นตอนการทำความสะอาดข้อมูล DH70.xlsx

## ข้อมูลพื้นฐาน
- **ไฟล์ต้นฉบับ**: DH70.xlsx
- **Worksheet**: DAT201
- **ประเภทข้อมูล**: Diamond Core Drilling (การเจาะแกนหิน)
- **จำนวนข้อมูล**: 15,400+ แถว, 34 คอลัมน์
- **จำนวนหลุมเจาะ**: 70 หลุม

## 🐍 ไฟล์ Python Scripts ที่ใช้

### 1. `src/data_processing/clean_and_create_db.py` (ไฟล์หลัก)
**หน้าที่**: ทำความสะอาดข้อมูลและสร้างฐานข้อมูล
```bash
python src/data_processing/clean_and_create_db.py
```

**สิ่งที่ทำ**:
- อ่านข้อมูลจาก data/raw/DH70.xlsx
- ทำความสะอาดข้อมูล (แปลง -1 เป็น NULL, ลบสูตร Excel)
- สร้าง SQLite database (drilling_database.db)
- สร้าง SQL Server script (drilling_database_sqlserver.sql)
- แยกข้อมูลเป็น 5 ตาราง

### 2. `src/data_processing/validate_database.py` (ไฟล์ตรวจสอบ)
**หน้าที่**: ตรวจสอบความถูกต้องของฐานข้อมูล
```bash
python src/data_processing/validate_database.py
```

**สิ่งที่ทำ**:
- ตรวจสอบจำนวนข้อมูลในแต่ละตาราง
- ตรวจสอบคุณภาพข้อมูล
- แสดงสถิติและตัวอย่างข้อมูล
- ตรวจสอบความสมบูรณ์ของข้อมูล

### 3. `Data_Cleaning_Tutorial_Polars.ipynb` (ไฟล์สอน)
**หน้าที่**: สอนการทำความสะอาดข้อมูลแบบทีละขั้นตอนด้วย Polars
```bash
jupyter notebook Data_Cleaning_Tutorial_Polars.ipynb
```

**สิ่งที่ทำ**:
- แสดงขั้นตอนการทำความสะอาดแบบละเอียด
- สร้างกราฟและ visualization
- อธิบายแต่ละขั้นตอนเป็นภาษาไทย
- ตัวอย่างการใช้งาน Polars (แทน pandas)

## 📊 ข้อมูลที่ได้หลังทำความสะอาด

### ตารางหลัก (5 ตาราง)
1. **COLLARS** - ข้อมูลปากหลุมเจาะ (70 หลุม)
2. **LITHOLOGY_LOGS** - ข้อมูลชั้นหิน (15,190 ช่วง)
3. **ROCK_TYPES** - ชนิดหิน (19 ชนิด)
4. **SEAM_CODES** - รหัสชั้นถ่าน (108 รหัส)
5. **SAMPLE_ANALYSES** - ผลวิเคราะห์ตัวอย่าง (0 ตัวอย่าง)

### ไฟล์ที่สร้างขึ้น
- `drilling_database.db` - SQLite database
- `data/processed/collars.csv` - ข้อมูลปากหลุม
- `data/processed/lithology_logs.csv` - ข้อมูลชั้นหิน
- `data/processed/sample_analyses.csv` - ข้อมูลการวิเคราะห์ตัวอย่าง
- `data/processed/rock_types.csv` - ข้อมูลประเภทหิน
- `data/processed/seam_codes.csv` - ข้อมูลรหัสชั้นถ่านหิน

## 🔧 การใช้งานไฟล์ Python

### วิธีรันไฟล์หลัก
```bash
# 1. ติดตั้ง dependencies
pip install -r requirements.txt

# 2. รันสคริปต์ทำความสะอาด
python src/data_processing/clean_and_create_db.py

# 3. ตรวจสอบผลลัพธ์
python src/data_processing/validate_database.py

# 4. ส่งออกเป็น CSV
python src/data_processing/export_sqlite_to_csv.py
```

### วิธีใช้ Jupyter Notebook
```bash
# 1. เปิด Jupyter Notebook
jupyter notebook

# 2. เปิดไฟล์ Data_Cleaning_Tutorial_Polars.ipynb
# 3. รันทีละ cell ตามลำดับ
```

## 📈 ผลลัพธ์ที่ได้

### ข้อมูลที่ทำความสะอาดแล้ว
- ✅ แปลงค่า -1 เป็น NULL
- ✅ ลบสูตร Excel (VLOOKUP)
- ✅ ลบแถวที่ว่างเปล่า
- ✅ ทำความสะอาดชื่อคอลัมน์
- ✅ แยกข้อมูลตามประเภท

### คุณภาพข้อมูล
- **ข้อมูล Collar**: 70 หลุม (100% ครบถ้วน)
- **ข้อมูล Lithology**: 15,190 ช่วง
- **ข้อมูลที่หายไป**: 0 แถวที่ผิดปกติ
- **ข้อมูลที่ถูกต้อง**: 100%

## 🎯 การใช้งานต่อไป

### สำหรับการวิเคราะห์
- ใช้ `drilling_database.db` กับ SQLite
- ใช้ `sample_sql_queries.sql` สำหรับ query ตัวอย่าง
- ใช้ `Data_Cleaning_Tutorial_Polars.ipynb` สำหรับการเรียนรู้

### สำหรับการนำเข้าฐานข้อมูลอื่น
- ใช้ไฟล์ CSV จาก `data/processed/` สำหรับ SQL Server Import Wizard
- ใช้ SQL scripts จาก `sql/` สำหรับสร้างตารางและความสัมพันธ์




