# Processed Data Files

## ไฟล์ที่จำเป็นสำหรับ SQL Server Import

### 1. `collars.csv`
- **ข้อมูล**: ตำแหน่งหลุมเจาะ
- **แถว**: 71 แถว
- **คอลัมน์**: hole_id, easting, northing, elevation, total_depth, inclination, year_drilled, geologist, block_no, dh_version, created_at

### 2. `rock_types.csv`
- **ข้อมูล**: ประเภทหิน
- **แถว**: 20 แถว
- **คอลัมน์**: rock_id, rock_code, rock_name

### 3. `seam_codes.csv` ⚠️ **ใช้ไฟล์นี้**
- **ข้อมูล**: รหัสชั้นถ่านหิน
- **แถว**: 97 แถว
- **คอลัมน์**: seam_code_id, seam_code, seam_label, seam_system
- **การแก้ไข**: เพิ่มคอลัมน์ `seam_code_id` (auto-increment)

### 4. `lithology_logs.csv` ⚠️ **ใช้ไฟล์นี้**
- **ข้อมูล**: บันทึกธรณีวิทยา
- **แถว**: 6,598 แถว
- **คอลัมน์**: log_id, hole_id, depth_from, depth_to, thickness, rock_code, description, clay_color, remark
- **การแก้ไข**: ลบอักขระพิเศษ, ตัดข้อความยาว

### 5. `sample_analyses.csv` ⚠️ **ใช้ไฟล์นี้**
- **ข้อมูล**: การวิเคราะห์ตัวอย่าง
- **แถว**: 8,592 แถว
- **คอลัมน์**: sample_id, hole_id, depth_from, depth_to, sample_no, im, tm, ash, vm, fc, sulphur, gross_cv, net_cv, sg, rd, hgi, seam_code_quality, seam_code_73, quality_seam_label, seam_label_73
- **การแก้ไข**: แก้ไข `net_cv` ให้เป็น `0.0` แทนค่าว่าง

## ไฟล์ที่ลบแล้ว

ไฟล์ต่อไปนี้ถูกลบออกเนื่องจากมีปัญหาในการนำเข้าข้อมูล:

- `sample_analyses_final.csv` - ใช้ค่าว่าง (มีปัญหา Data Conversion)
- `sample_analyses_fixed.csv` - ใช้ `NULL` string (มีปัญหา)
- `sample_analyses_fixed_v2.csv` - ใช้ `""` (มีปัญหา)
- `seam_codes_fixed.csv` - เปลี่ยนชื่อเป็น `seam_codes.csv`
- `lithology_logs_ultra_clean.csv` - เปลี่ยนชื่อเป็น `lithology_logs.csv`

## การใช้งาน

ใช้ไฟล์เหล่านี้สำหรับ SQL Server Import Wizard ตามลำดับ:

1. COLLARS → `collars.csv`
2. ROCK_TYPES → `rock_types.csv`
3. SEAM_CODES → `seam_codes.csv`
4. LITHOLOGY_LOGS → `lithology_logs.csv`
5. SAMPLE_ANALYSES → `sample_analyses.csv`

## หมายเหตุ

- ไฟล์ทั้งหมดได้รับการแก้ไขเพื่อให้สามารถนำเข้าข้อมูลได้โดยไม่มีปัญหา
- ใช้ไฟล์ที่มีเครื่องหมาย ⚠️ เท่านั้น
- ตรวจสอบว่าไฟล์ CSV มี header row
- ตั้งค่า Error Output เป็น "Redirect row" ใน Import Wizard

