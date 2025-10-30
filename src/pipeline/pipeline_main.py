#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pipeline Orchestrator: Build normalized CSVs from DH70.xlsx using modular extractors.
Outputs CSVs to data/normalized_sql_server/ matching the SQL load scripts.
"""

import os
from datetime import datetime

from .extract_seam_codes import extract_seam_codes
from .extract_rock_types import extract_rock_types
from .extract_collars import extract_collars
from .extract_lithology_logs import extract_lithology_logs
from .extract_sample_analyses import extract_sample_analyses


def run_pipeline(excel_path: str = "data/raw/DH70.xlsx") -> None:
	os.makedirs('data/normalized_sql_server', exist_ok=True)

	# 1) Seam Codes (standard name)
	seam_df = extract_seam_codes(excel_path)
	seam_path = 'data/normalized_sql_server/seam_codes_lookup.csv'
	seam_df.to_csv(seam_path, index=False)
	print(f"✓ Seam codes: {len(seam_df)} -> {seam_path}")

	# 2) Rock Types
	rock_df = extract_rock_types(excel_path)
	rock_path = 'data/normalized_sql_server/rock_types.csv'
	rock_df.to_csv(rock_path, index=False)
	print(f"✓ Rock types: {len(rock_df)} -> {rock_path}")

	# 3) Collars
	collars_df = extract_collars(excel_path)
	collars_path = 'data/normalized_sql_server/collars.csv'
	collars_df.to_csv(collars_path, index=False)
	print(f"✓ Collars: {len(collars_df)} -> {collars_path}")

	# 4) Lithology Logs
	lith_df = extract_lithology_logs(excel_path)
	lith_path = 'data/normalized_sql_server/lithology_logs.csv'
	lith_df.to_csv(lith_path, index=False)
	print(f"✓ Lithology logs: {len(lith_df)} -> {lith_path}")

	# 5) Sample Analyses
	samples_df = extract_sample_analyses(excel_path)
	samples_path = 'data/normalized_sql_server/sample_analyses.csv'
	samples_df.to_csv(samples_path, index=False)
	print(f"✓ Sample analyses: {len(samples_df)} -> {samples_path}")


if __name__ == '__main__':
	print("=" * 80)
	print("RUNNING DATA PIPELINE - DH70.xlsx → normalized CSVs")
	print("=" * 80)
	run_pipeline()
	print("\nAll outputs ready under data/normalized_sql_server/")
