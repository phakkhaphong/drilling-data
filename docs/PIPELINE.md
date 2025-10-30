# Data Pipeline (DH70.xlsx → Normalized CSVs)

This document describes the modular extractors and the orchestrator.

## Modules

- Seam Codes: `src/pipeline/extract_seam_codes.py`
  - Reads worksheet `Seam Code` and extracts systems 30, 46, 57, 58, Quality, 73
  - Output: `data/normalized_sql_server/seam_codes_lookup.csv`
  - Columns: `seam_id, system_id, system_name, seam_label, seam_code, priority, description, created_at`

- Rock Types: `src/pipeline/extract_rock_types.py`
  - Reads `Rock Code` and outputs combined rock codes/types → `rock_types.csv`

- Collars: `src/pipeline/extract_collars.py`
  - Reads `DAT201` and aggregates unique holes with final depth → `collars.csv`

- Lithology Logs: `src/pipeline/extract_lithology_logs.py`
  - Reads `DAT201` per-interval depth and description → `lithology_logs.csv`

- Sample Analyses: `src/pipeline/extract_sample_analyses.py`
  - Reads `DAT201`, filters invalid values, outputs proximate analysis fields → `sample_analyses.csv`

## Orchestrator

- `src/pipeline/pipeline_main.py`
  - Runs all extractors and writes to `data/normalized_sql_server/`

Run:
```bash
python -m pipeline.pipeline_main
```

## SQL Integration

- Schema: `sql/create_sql_server_schema.sql`
- Load: `sql/load_sql_server_data.sql`
- Sample queries: `sql/sample_sql_queries_updated.sql`

## Extending

- Add a new extractor file in `src/pipeline/` and register it in `pipeline_main.py`.
- Keep CSV headers consistent with schema.
