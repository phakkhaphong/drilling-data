#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extractor: Lithology Logs from DH70.xlsx (DAT201 worksheet)
Outputs a DataFrame with columns:
  log_id, hole_id, depth_from, depth_to, rock_code, description, created_at
- rock_code is taken directly from DAT201 'Rock' column to preserve relationships
- sorted by hole_id, depth_from
"""

import pandas as pd
import openpyxl
from datetime import datetime
from typing import Optional


def extract_lithology_logs(excel_path: str = "data/raw/DH70.xlsx") -> pd.DataFrame:
	wb = openpyxl.load_workbook(excel_path, data_only=True)
	ws = wb['DAT201']
	data = []
	for row in ws.iter_rows(values_only=True):
		if any(cell is not None for cell in row):
			data.append(row)
	wb.close()
	df = pd.DataFrame(data[1:], columns=data[0])

	rows = []
	log_seq = 1
	for _, row in df.iterrows():
		try:
			rock_val = row.get('Rock')
			rock_code: Optional[int] = None
			if rock_val is not None and str(rock_val).strip() != '':
				try:
					rock_code = int(float(rock_val))
				except Exception:
					rock_code = None

			rows.append({
				'log_id': log_seq,
				'hole_id': str(row.get('DHID')).strip() if row.get('DHID') else None,
				'depth_from': float(row.get('From')) if row.get('From') is not None else None,
				'depth_to': float(row.get('To')) if row.get('To') is not None else None,
				'rock_code': rock_code,
				'description': str(row.get('Lithology')).strip() if row.get('Lithology') else None,
				'created_at': datetime.now(),
			})
			log_seq += 1
		except Exception:
			pass

	out = pd.DataFrame(rows)
	# Sort by hole and depth
	out = out.sort_values(by=['hole_id', 'depth_from'], kind='stable').reset_index(drop=True)
	# Reassign log_id sequentially after sort
	out['log_id'] = range(1, len(out) + 1)
	# rock_code as nullable integer to avoid floats in CSV
	out['rock_code'] = out['rock_code'].astype('Int64')
	# Ensure column order
	out = out[['log_id', 'hole_id', 'depth_from', 'depth_to', 'rock_code', 'description', 'created_at']]
	return out


__all__ = ["extract_lithology_logs"]
