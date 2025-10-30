#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Load normalized CSVs into SQL Server using pymssql (no sqlcmd/bcp required).
- Runs schema from sql/create_sql_server_schema.sql (splits on GO)
- Inserts CSVs for: seam_codes_lookup, rock_types, collars, lithology_logs, sample_analyses
- Uses IDENTITY_INSERT where needed
Usage:
  python scripts/load_to_sqlserver.py --server 35.247.159.73 --db HongsaDB --user hongsa --password 'Pa55w.rd'
"""

import argparse
import csv
import os
import pymssql

PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
SQL_DIR = os.path.join(PROJECT_ROOT, 'sql')
DATA_DIR = os.path.join(PROJECT_ROOT, 'data', 'normalized_sql_server')


def run_sql_file(conn, path):
	with open(path, 'r', encoding='utf-8') as f:
		text = f.read()
	# Split on lines that are exactly GO
	batches = []
	batch = []
	for line in text.splitlines():
		if line.strip().upper() == 'GO':
			batches.append('\n'.join(batch))
			batch = []
		else:
			batch.append(line)
	if batch:
		batches.append('\n'.join(batch))

	with conn.cursor() as cur:
		for b in batches:
			stmt = b.strip()
			if not stmt:
				continue
			cur.execute(stmt)
		conn.commit()


def insert_csv(conn, table, columns, csv_path, keep_identity=False, batch_size: int = 5000):
    total_inserted = 0
    placeholders = ','.join(['%s'] * len(columns))
    col_list = ','.join(columns)
    with conn.cursor() as cur, open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader, None)  # skip header
        if keep_identity:
            cur.execute(f"SET IDENTITY_INSERT {table} ON;")
        batch = []
        for row in reader:
            batch.append(tuple((None if v == '' else v) for v in row))
            if len(batch) >= batch_size:
                cur.executemany(
                    f"INSERT INTO {table} ({col_list}) VALUES ({placeholders})",
                    batch,
                )
                total_inserted += len(batch)
                batch.clear()
        if batch:
            cur.executemany(
                f"INSERT INTO {table} ({col_list}) VALUES ({placeholders})",
                batch,
            )
            total_inserted += len(batch)
        if keep_identity:
            cur.execute(f"SET IDENTITY_INSERT {table} OFF;")
    conn.commit()
    return total_inserted


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument('--server', required=True)
	ap.add_argument('--db', required=True)
	ap.add_argument('--user', required=True)
	ap.add_argument('--password', required=True)
	args = ap.parse_args()

	conn = pymssql.connect(server=args.server, user=args.user, password=args.password, database=args.db)
	try:
		# 1) Run schema
		run_sql_file(conn, os.path.join(SQL_DIR, 'create_sql_server_schema.sql'))

		# 2) Load data
		loaded = {}
		loaded['seam_codes_lookup'] = insert_csv(
			conn,
			'tdbo.seam_codes_lookup'.replace('tdbo.', 'dbo.'),
			['seam_id','system_id','system_name','seam_label','seam_code','priority','description','created_at'],
			os.path.join(DATA_DIR, 'seam_codes_lookup.csv'),
			keep_identity=True,
		)
		loaded['rock_types'] = insert_csv(
			conn,
			'dbo.rock_types',
			['rock_code','lithology','detail','created_at'],
			os.path.join(DATA_DIR, 'rock_types.csv'),
			keep_identity=False,
		)
		loaded['collars'] = insert_csv(
			conn,
			'dbo.collars',
			['collar_id','hole_id','easting','northing','elevation','final_depth','dip','drilling_date','azimuth','contractor','remarks','created_at','updated_at'],
			os.path.join(DATA_DIR, 'collars.csv'),
			keep_identity=True,
		)
		loaded['lithology_logs'] = insert_csv(
			conn,
			'dbo.lithology_logs',
			['log_id','hole_id','depth_from','depth_to','rock_code','description','created_at'],
			os.path.join(DATA_DIR, 'lithology_logs.csv'),
			keep_identity=True,
		)
		loaded['sample_analyses'] = insert_csv(
			conn,
			'dbo.sample_analyses',
			['sample_id','hole_id','depth_from','depth_to','sample_no','im','tm','ash','vm','fc','sulphur','gross_cv','net_cv','sg','rd','hgi','seam_quality_id','seam_73_id','seam_code_quality_original','analysis_date','lab_name','remarks','created_at','updated_at'],
			os.path.join(DATA_DIR, 'sample_analyses.csv'),
			keep_identity=True,
		)

		# 3) Report counts
		with conn.cursor(as_dict=True) as cur:
			cur.execute("SELECT 'seam_codes' t, COUNT(*) c FROM seam_codes_lookup UNION ALL SELECT 'rock_types', COUNT(*) FROM rock_types UNION ALL SELECT 'collars', COUNT(*) FROM collars UNION ALL SELECT 'lithology_logs', COUNT(*) FROM lithology_logs UNION ALL SELECT 'sample_analyses', COUNT(*) FROM sample_analyses;")
			rows = cur.fetchall()
		for r in rows:
			print(f"{r['t']}: {r['c']}")
	finally:
		conn.close()


if __name__ == '__main__':
	main()

