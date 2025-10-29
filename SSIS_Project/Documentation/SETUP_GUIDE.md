# คำแนะนำการสร้าง SSIS Project บนเครื่อง Server

## ปัญหาที่พบ
SSIS Extension 1.6.2 ต้องการ SSIS Build Targets ที่ติดตั้งพร้อมกับ Visual Studio และ Extension
ถ้าไม่มีไฟล์ Build Targets ในเครื่อง project จะไม่สามารถโหลดได้

## วิธีแก้ไข (แนะนำ)

### ขั้นตอนที่ 1: สร้าง SSIS Project ใหม่บนเครื่อง Server
1. เปิด Visual Studio 2022 บนเครื่อง Server ที่มี SSIS Extension 1.6.2 ติดตั้งอยู่แล้ว
2. สร้าง New Project → เลือก **Integration Services Project**
3. ตั้งชื่อ project: **DrillingDataETL**
4. เลือกตำแหน่งที่จะสร้าง project

### ขั้นตอนที่ 2: คัดลอกไฟล์ Packages และ Connections
1. คัดลอกไฟล์จาก `SSIS_Project/DrillingDataETL/Packages/` ทั้งหมด:
   - MainETL.dtsx
   - LoadCollars.dtsx
   - LoadSampleAnalyses.dtsx
   
2. คัดลอกไฟล์จาก `SSIS_Project/DrillingDataETL/Connections/` ทั้งหมด:
   - Excel_Connection.conmgr
   - SQL_Server_Connection.conmgr
   - CSV_Connection.conmgr

3. ใน Visual Studio:
   - Right-click ที่ **Packages** → Add → Existing Package → เลือกไฟล์ .dtsx ทั้งหมด
   - Right-click ที่ **Connection Managers** → Add Existing Connection → เลือกไฟล์ .conmgr ทั้งหมด

### ขั้นตอนที่ 3: ตั้งค่า Project Parameters
1. ใน Visual Studio → Right-click ที่ Project → Properties
2. ไปที่แท็บ **Parameters**
3. เพิ่ม Parameters ต่อไปนี้:
   - **ExcelFilePath** (String): `data/raw/DH70.xlsx`
   - **SQLServerInstance** (String): `localhost`
   - **DatabaseName** (String): `DrillingDatabase`
   - **ProcessedDataPath** (String): `data/processed`
   - **LogLevel** (Int32): `4`
   - **MaxConcurrentExecutables** (Int32): `4`
   - **ErrorOutputPath** (String): `data/error`
   - **BatchSize** (Int32): `1000`

### ขั้นตอนที่ 4: ตรวจสอบและแก้ไข Connection Managers
1. เปิดแต่ละ Connection Manager ใน Visual Studio
2. ตรวจสอบ Connection String และแก้ไขให้ใช้ Project Parameters:
   - Excel_Connection: ใช้ `@[$Project::ExcelFilePath]`
   - SQL_Server_Connection: ใช้ `@[$Project::SQLServerInstance]` และ `@[$Project::DatabaseName]`
   - CSV_Connection: ใช้ `@[$Project::ProcessedDataPath]`

### ขั้นตอนที่ 5: Build และทดสอบ
1. Build Project (F6)
2. ตรวจสอบว่าไม่มี Error
3. Run Package เพื่อทดสอบ

## หมายเหตุ
- Project file (.dtproj) ที่สร้างโดย Visual Studio จะมี Import statement ที่ถูกต้องสำหรับเครื่อง Server
- ไฟล์ Packages และ Connections ที่สร้างไว้แล้วสามารถนำไปใช้ได้เลย
- Project Parameters จะถูกสร้างอัตโนมัติเมื่อเพิ่มใน Visual Studio
