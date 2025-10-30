# Hongsa Drilling Data Pipeline

This repository builds a normalized coal drilling dataset from `data/raw/DH70.xlsx` and prepares CSVs for Microsoft SQL Server.

## Pipeline (Modular Extractors)

- `src/pipeline/extract_seam_codes.py` → `seam_codes_lookup.csv`
- `src/pipeline/extract_rock_types.py` → `rock_types.csv`
- `src/pipeline/extract_collars.py` → `collars.csv`
- `src/pipeline/extract_lithology_logs.py` → `lithology_logs.csv`
- `src/pipeline/extract_sample_analyses.py` → `sample_analyses.csv`
- Orchestrator: `src/pipeline/pipeline_main.py`

Outputs are written to `data/normalized_sql_server/` and align with `sql/*.sql`.

## Quick Start

1) Create normalized CSVs

```bash
python -m pipeline.pipeline_main
```

2) Create schema and load data to SQL Server

```bash
sqlcmd -S <server> -d <database> -i sql/create_sql_server_schema.sql
sqlcmd -S <server> -d <database> -i sql/load_sql_server_data.sql
```

## Notes

- Legacy monolithic scripts have been removed in favor of modular extractors.
- The schema references unified `rock_types` and `seam_codes_lookup`.
- Sample queries: see `sql/sample_sql_queries_updated.sql`.