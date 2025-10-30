#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extractor: Sample Analyses from DH70.xlsx (DAT201 worksheet)
Outputs a DataFrame with columns matching sample_analyses.csv used by SQL scripts.
"""

import pandas as pd
import openpyxl
from datetime import datetime
from typing import Optional, List


def _clean_value(val):
	if val is None or val == '' or val == -1.0:
		return None
	try:
		return float(val)
	except Exception:
		return None


def extract_sample_analyses(excel_path: str = "data/raw/DH70.xlsx") -> pd.DataFrame:
	wb = openpyxl.load_workbook(excel_path, data_only=True)
	ws = wb['DAT201']
	data = []
	for row in ws.iter_rows(values_only=True):
		if any(cell is not None for cell in row):
			data.append(row)
	wb.close()
	df = pd.DataFrame(data[1:], columns=data[0])

	analysis_columns: List[str] = ['IM', 'TM', 'Ash', 'VM', 'FC', 'Sulphur', 'RD', 'HGI']
	available: List[str] = [c for c in analysis_columns if c in df.columns]
	mask = df[available].notna().any(axis=1)
	valid_mask = ~((df[available] == -1.0) | (df[available].isna())).all(axis=1)
	adf = df[mask & valid_mask]

	rows = []
	sample_id = 1
	for _, r in adf.iterrows():
		# ensure we have at least one valid metric
		if not any(_clean_value(r.get(c)) is not None for c in available):
			continue
		rows.append({
			'sample_id': sample_id,
			'hole_id': str(r.get('DHID')).strip() if r.get('DHID') else None,
			'depth_from': _clean_value(r.get('From')),
			'depth_to': _clean_value(r.get('To')),
			'sample_no': f"{r.get('DHID')}_{sample_id}" if r.get('DHID') else None,
			'im': _clean_value(r.get('IM')),
			'tm': _clean_value(r.get('TM')),
			'ash': _clean_value(r.get('Ash')),
			'vm': _clean_value(r.get('VM')),
			'fc': _clean_value(r.get('FC')),
			'sulphur': _clean_value(r.get('Sulphur')),
			'gross_cv': None,
			'net_cv': None,
			'sg': None,
			'rd': _clean_value(r.get('RD')),
			'hgi': _clean_value(r.get('HGI')),
			'seam_quality_id': None,
			'seam_73_id': None,
			'seam_code_quality_original': None,
			'analysis_date': None,
			'lab_name': None,
			'remarks': None,
			'created_at': datetime.now(),
			'updated_at': datetime.now(),
		})
		sample_id += 1

	return pd.DataFrame(rows)


__all__ = ["extract_sample_analyses"]

