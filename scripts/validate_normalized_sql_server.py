import argparse
import os
from dataclasses import dataclass
from typing import List, Optional

import pandas as pd


@dataclass
class CheckResult:
    name: str
    passed: bool
    details: Optional[str] = None
    issues: Optional[pd.DataFrame] = None


def read_csv_safe(path: str, dtype=None) -> pd.DataFrame:
    return pd.read_csv(path, dtype=dtype, keep_default_na=True, na_values=["", " ", "NA", "NaN", "nan"])


def check_hole_referential_integrity(collars: pd.DataFrame, lith: pd.DataFrame, samples: pd.DataFrame) -> List[CheckResult]:
    results: List[CheckResult] = []

    # collars.hole_id must be unique and not null
    null_holes = collars[collars["hole_id"].isna()][["collar_id", "hole_id"]]
    dup_mask = collars["hole_id"].duplicated(keep=False)
    dup_holes = collars.loc[dup_mask, ["collar_id", "hole_id"]].sort_values("hole_id")
    results.append(
        CheckResult(
            name="collars.hole_id not null",
            passed=len(null_holes) == 0,
            details=f"null count={len(null_holes)}" if len(null_holes) else None,
            issues=null_holes if len(null_holes) else None,
        )
    )
    results.append(
        CheckResult(
            name="collars.hole_id unique",
            passed=len(dup_holes) == 0,
            details=f"duplicate holes={dup_holes['hole_id'].nunique()}" if len(dup_holes) else None,
            issues=dup_holes if len(dup_holes) else None,
        )
    )

    # lithology_logs.hole_id must exist in collars
    lith_bad = lith[~lith["hole_id"].isin(collars["hole_id"])][["log_id", "hole_id", "depth_from", "depth_to"]]
    results.append(
        CheckResult(
            name="lithology_logs.hole_id references collars",
            passed=len(lith_bad) == 0,
            details=f"missing count={len(lith_bad)}" if len(lith_bad) else None,
            issues=lith_bad if len(lith_bad) else None,
        )
    )

    # sample_analyses.hole_id must exist in collars
    samp_bad = samples[~samples["hole_id"].isin(collars["hole_id"])][["sample_id", "hole_id", "depth_from", "depth_to", "sample_no"]]
    results.append(
        CheckResult(
            name="sample_analyses.hole_id references collars",
            passed=len(samp_bad) == 0,
            details=f"missing count={len(samp_bad)}" if len(samp_bad) else None,
            issues=samp_bad if len(samp_bad) else None,
        )
    )

    return results


def check_rock_codes(lith: pd.DataFrame, rock_types: pd.DataFrame) -> List[CheckResult]:
    results: List[CheckResult] = []
    rock_types = rock_types.copy()
    lith = lith.copy()

    # normalize dtypes
    rock_types["rock_code"] = pd.to_numeric(rock_types["rock_code"], errors="coerce").astype("Int64")
    lith["rock_code"] = pd.to_numeric(lith["rock_code"], errors="coerce").astype("Int64")

    # FK: lith.rock_code must exist in rock_types.rock_code
    missing_rock = lith[~lith["rock_code"].isin(rock_types["rock_code"])][["log_id", "hole_id", "rock_code", "description"]]
    results.append(
        CheckResult(
            name="lithology_logs.rock_code references rock_types",
            passed=len(missing_rock) == 0,
            details=f"missing count={len(missing_rock)}" if len(missing_rock) else None,
            issues=missing_rock if len(missing_rock) else None,
        )
    )

    # Semantic: lith.description (code like CL/CBCL) should match rock_types.lithology
    joined = lith.merge(rock_types[["rock_code", "lithology"]], on="rock_code", how="left")
    mismatch = joined[(~joined["description"].isna()) & (joined["description"].astype(str) != joined["lithology"].astype(str))][
        ["log_id", "hole_id", "rock_code", "description", "lithology"]
    ]
    results.append(
        CheckResult(
            name="lithology_logs.description matches rock_types.lithology",
            passed=len(mismatch) == 0,
            details=f"mismatch count={len(mismatch)}" if len(mismatch) else None,
            issues=mismatch if len(mismatch) else None,
        )
    )

    return results


def check_depth_intervals(lith: pd.DataFrame, samples: pd.DataFrame) -> List[CheckResult]:
    results: List[CheckResult] = []

    # Basic interval sanity
    lith_bad_bounds = lith[(lith["depth_from"].isna()) | (lith["depth_to"].isna()) | (lith["depth_from"] >= lith["depth_to"])][
        ["log_id", "hole_id", "depth_from", "depth_to"]
    ]
    results.append(
        CheckResult(
            name="lithology_logs intervals have depth_from < depth_to",
            passed=len(lith_bad_bounds) == 0,
            details=f"invalid intervals={len(lith_bad_bounds)}" if len(lith_bad_bounds) else None,
            issues=lith_bad_bounds if len(lith_bad_bounds) else None,
        )
    )

    samp_bad_bounds = samples[(samples["depth_from"].isna()) | (samples["depth_to"].isna()) | (samples["depth_from"] >= samples["depth_to"])][
        ["sample_id", "hole_id", "depth_from", "depth_to", "sample_no"]
    ]
    results.append(
        CheckResult(
            name="sample_analyses intervals have depth_from < depth_to",
            passed=len(samp_bad_bounds) == 0,
            details=f"invalid intervals={len(samp_bad_bounds)}" if len(samp_bad_bounds) else None,
            issues=samp_bad_bounds if len(samp_bad_bounds) else None,
        )
    )

    # Overlaps in lithology per hole
    def find_overlaps(df: pd.DataFrame) -> pd.DataFrame:
        overlaps: List[pd.DataFrame] = []
        for hole_id, g in df.sort_values(["hole_id", "depth_from", "depth_to"]).groupby("hole_id"):
            prev_to = None
            prev_row = None
            for _, row in g.iterrows():
                if prev_to is not None and row["depth_from"] < prev_to - 1e-9:
                    overlaps.append(pd.DataFrame({
                        "hole_id": [hole_id],
                        "prev_log_id": [prev_row["log_id"]],
                        "prev_to": [prev_to],
                        "log_id": [row["log_id"]],
                        "depth_from": [row["depth_from"]],
                        "depth_to": [row["depth_to"]],
                    }))
                prev_to = row["depth_to"]
                prev_row = row
        return pd.concat(overlaps, ignore_index=True) if overlaps else pd.DataFrame(columns=["hole_id", "prev_log_id", "prev_to", "log_id", "depth_from", "depth_to"])

    overlaps = find_overlaps(lith)
    results.append(
        CheckResult(
            name="lithology_logs have no overlapping intervals per hole",
            passed=len(overlaps) == 0,
            details=f"overlap count={len(overlaps)}" if len(overlaps) else None,
            issues=overlaps if len(overlaps) else None,
        )
    )

    # Samples should fall within at least one lith interval for the same hole
    # Fast-ish check via merge-asof style: for each sample, find lith with depth_from <= sample_from then test depth_to >= sample_to
    samp = samples.sort_values(["hole_id", "depth_from"]).copy()
    lith_sorted = lith.sort_values(["hole_id", "depth_from"]).copy()

    unmatched_rows: List[pd.DataFrame] = []
    for hole_id, g_samp in samp.groupby("hole_id"):
        g_lith = lith_sorted[lith_sorted["hole_id"] == hole_id]
        if g_lith.empty:
            unmatched_rows.append(g_samp[["sample_id", "hole_id", "depth_from", "depth_to", "sample_no"]])
            continue
        # For each sample interval, check coverage
        # Use a left-merge on depth_from less-equal via searchsorted
        lith_starts = g_lith["depth_from"].to_numpy()
        lith_ends = g_lith["depth_to"].to_numpy()
        lith_ids = g_lith["log_id"].to_numpy()
        idxs = lith_starts.searchsorted(g_samp["depth_from"].to_numpy(), side="right") - 1
        idxs[idxs < 0] = -1

        rows: List[pd.DataFrame] = []
        for (i, (_, sr)) in enumerate(g_samp.iterrows()):
            j = int(idxs[i])
            ok = False
            matched_log = None
            if j >= 0:
                if sr["depth_to"] <= lith_ends[j] + 1e-9:
                    ok = True
                    matched_log = int(lith_ids[j])
            if not ok:
                rows.append(pd.DataFrame({
                    "sample_id": [sr["sample_id"]],
                    "hole_id": [sr["hole_id"]],
                    "depth_from": [sr["depth_from"]],
                    "depth_to": [sr["depth_to"]],
                    "sample_no": [sr["sample_no"]],
                    "matched_log_id": [matched_log],
                }))
        if rows:
            unmatched_rows.append(pd.concat(rows, ignore_index=True))

    unmatched = pd.concat(unmatched_rows, ignore_index=True) if unmatched_rows else pd.DataFrame(columns=["sample_id", "hole_id", "depth_from", "depth_to", "sample_no", "matched_log_id"])
    results.append(
        CheckResult(
            name="sample_analyses intervals covered by lithology intervals",
            passed=len(unmatched) == 0,
            details=f"uncovered samples={len(unmatched)}" if len(unmatched) else None,
            issues=unmatched if len(unmatched) else None,
        )
    )

    return results


def check_seam_codes(samples: pd.DataFrame, seam_lookup: pd.DataFrame) -> List[CheckResult]:
    results: List[CheckResult] = []
    if "seam_code_quality_original" not in samples.columns:
        return results

    seam_lookup = seam_lookup.copy()
    seam_lookup["seam_code"] = seam_lookup["seam_code"].astype(str)
    samples = samples.copy()
    samples["seam_code_quality_original"] = samples["seam_code_quality_original"].astype(str)

    non_null = samples[~samples["seam_code_quality_original"].isin(["None", "nan", "NaN"])].copy()
    missing = non_null[~non_null["seam_code_quality_original"].isin(seam_lookup["seam_code"])][[
        "sample_id", "hole_id", "sample_no", "seam_code_quality_original"
    ]]
    results.append(
        CheckResult(
            name="sample_analyses.seam_code_quality_original references seam_codes_lookup",
            passed=len(missing) == 0,
            details=f"missing seam codes={len(missing)}" if len(missing) else None,
            issues=missing if len(missing) else None,
        )
    )
    return results


def main(data_dir: str, out_dir: str) -> None:
    os.makedirs(out_dir, exist_ok=True)

    collars = read_csv_safe(os.path.join(data_dir, "collars.csv"))
    lith = read_csv_safe(os.path.join(data_dir, "lithology_logs.csv"))
    samples = read_csv_safe(os.path.join(data_dir, "sample_analyses.csv"))
    rock_types = read_csv_safe(os.path.join(data_dir, "rock_types.csv"))
    seam_lookup = read_csv_safe(os.path.join(data_dir, "seam_codes_lookup.csv"))

    # Normalize numeric columns
    for df, cols in (
        (lith, ["depth_from", "depth_to", "rock_code"]),
        (samples, ["depth_from", "depth_to"]),
    ):
        for c in cols:
            if c in df.columns:
                df[c] = pd.to_numeric(df[c], errors="coerce")

    all_results: List[CheckResult] = []
    all_results += check_hole_referential_integrity(collars, lith, samples)
    all_results += check_rock_codes(lith, rock_types)
    all_results += check_depth_intervals(lith, samples)
    all_results += check_seam_codes(samples, seam_lookup)

    # Write issues to CSVs and print summary
    summary_rows = []
    for res in all_results:
        summary_rows.append({"check": res.name, "passed": res.passed, "details": res.details or ""})
        if res.issues is not None and not res.issues.empty:
            safe_name = (
                res.name.lower()
                .replace(" ", "_")
                .replace("/", "_")
                .replace("(", "")
                .replace(")", "")
            )
            out_path = os.path.join(out_dir, f"{safe_name}.csv")
            res.issues.to_csv(out_path, index=False)

    summary = pd.DataFrame(summary_rows, columns=["check", "passed", "details"]).sort_values("check")
    summary_path = os.path.join(out_dir, "summary.csv")
    summary.to_csv(summary_path, index=False)

    print("Validation summary:\n")
    print(summary.to_string(index=False))
    print(f"\nDetailed issue files (if any) written to: {out_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate normalized SQL Server lithology-related CSVs for consistency.")
    parser.add_argument(
        "--data-dir",
        default=os.path.join(os.path.dirname(__file__), "..", "data", "normalized_sql_server"),
        help="Directory containing the CSV files",
    )
    parser.add_argument(
        "--out-dir",
        default=os.path.join(os.path.dirname(__file__), "..", "reports", "normalized_sql_server_validation"),
        help="Directory to write validation reports",
    )
    args = parser.parse_args()
    main(os.path.abspath(args.data_dir), os.path.abspath(args.out_dir))


