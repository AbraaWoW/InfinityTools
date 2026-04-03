#!/usr/bin/env python3
"""
Generate an EU-only Mythic Dashboard dataset block for RevMplusInfoMythicFrame.lua.

The addon does not fetch Raider.IO data live. Instead, this script consumes an
exported score dataset and rewrites the embedded `RevMRH_PYTHON_DATA` block.

Accepted input formats:
1. JSON array of numbers
   Example: [3021.55, 2877.20, 2500.00]
2. JSON array of objects with a score field
   Supported keys: score, mythic_plus_score, mythicPlusScore, rio_score
3. JSON object containing one of:
   - {"scores": [...]}
   - {"characters": [...]}
4. CSV with a header row containing a score column
   Supported score columns: score, mythic_plus_score, mythicPlusScore, rio_score
   Optional region columns: region, region_slug, wow_region

If a region column exists, rows are filtered to the requested region.
If no region information exists, the input is assumed to already be region-filtered.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
import pathlib
import re
import sys
from typing import List, Sequence


ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / "InfinityMythicPlus" / "Modules" / "RevMplusInfoMythicFrame.lua"
PERCENTILES = [0.1, 1, 10, 25, 40, 50, 60, 70]
SCORE_KEYS = ("score", "mythic_plus_score", "mythicPlusScore", "rio_score")
REGION_KEYS = ("region", "region_slug", "wow_region")


def normalize_region(value: object) -> str:
    text = str(value or "").strip().upper()
    aliases = {
        "EU": "EU",
        "EUROPE": "EU",
        "US": "US",
        "AMERICAS": "US",
        "KR": "KR",
        "TW": "TW",
        "CN": "CN",
    }
    return aliases.get(text, text)


def extract_score(item: object) -> float | None:
    if isinstance(item, (int, float)):
        return float(item)
    if not isinstance(item, dict):
        return None

    for key in SCORE_KEYS:
        value = item.get(key)
        if value is not None:
            try:
                return float(value)
            except (TypeError, ValueError):
                return None

    mps = item.get("mythic_plus_scores")
    if isinstance(mps, dict):
        for key in ("all", "overall"):
            value = mps.get(key)
            if value is not None:
                try:
                    return float(value)
                except (TypeError, ValueError):
                    return None
    return None


def extract_region(item: object) -> str | None:
    if not isinstance(item, dict):
        return None
    for key in REGION_KEYS:
        value = item.get(key)
        if value not in (None, ""):
            return normalize_region(value)
    return None


def load_json_scores(path: pathlib.Path, region: str) -> List[float]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, dict):
        for key in ("scores", "characters", "results", "data"):
            if key in payload and isinstance(payload[key], list):
                payload = payload[key]
                break

    if not isinstance(payload, list):
        raise ValueError("JSON input must be a list or contain a list under scores/characters/results/data.")

    scores: List[float] = []
    for item in payload:
        item_region = extract_region(item)
        if item_region and item_region != region:
            continue
        score = extract_score(item)
        if score is not None:
            scores.append(score)
    return scores


def load_csv_scores(path: pathlib.Path, region: str) -> List[float]:
    scores: List[float] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError("CSV input must contain a header row.")

        score_key = next((name for name in reader.fieldnames if name in SCORE_KEYS), None)
        if score_key is None:
            raise ValueError(f"CSV input must include one of these score columns: {', '.join(SCORE_KEYS)}")

        region_key = next((name for name in reader.fieldnames if name in REGION_KEYS), None)
        for row in reader:
            if region_key and normalize_region(row.get(region_key)) != region:
                continue
            try:
                scores.append(float(row[score_key]))
            except (TypeError, ValueError):
                continue
    return scores


def load_scores(path: pathlib.Path, region: str) -> List[float]:
    suffix = path.suffix.lower()
    if suffix == ".json":
        return load_json_scores(path, region)
    if suffix == ".csv":
        return load_csv_scores(path, region)
    raise ValueError("Unsupported input file type. Use .json or .csv.")


def percentile_score(sorted_scores: Sequence[float], percentile: float) -> tuple[float, int]:
    total = len(sorted_scores)
    count = max(1, math.floor(total * percentile / 100))
    index = min(count - 1, total - 1)
    return sorted_scores[index], count


def build_rank_table(scores: Sequence[float]) -> List[dict]:
    sorted_scores = sorted(scores, reverse=True)
    rank_table: List[dict] = []
    for pct in PERCENTILES:
        score, count = percentile_score(sorted_scores, pct)
        rank_table.append({
            "label": f"{pct:g}%",
            "score": round(score, 2),
            "count": count,
        })
    return rank_table


def render_lua_block(rank_table: Sequence[dict], total: int, region: str, source: str, data_time: str) -> str:
    lines = [
        "local RevMRH_PYTHON_DATA = {",
        "    RankTable = {",
    ]
    for row in rank_table:
        lines.append(
            f'        {{ label = "{row["label"]}", score = {row["score"]:.2f}, count = {row["count"]} }},'
        )
    lines.extend(
        [
            "    },",
            f'    PopulationLabel = "{region}",',
            f"    TotalPopulation = {total},",
            f'    DataTime = "{data_time}",',
            f'    Source = "{source}",',
            '    InfinityVersion = "generated",',
            "}",
        ]
    )
    return "\n".join(lines)


def patch_target(target: pathlib.Path, replacement_block: str) -> None:
    text = target.read_text(encoding="utf-8")
    pattern = re.compile(
        r"(-- \[\[ PYTHON_DATA_START \]\]\s*\n)local RevMRH_PYTHON_DATA = \{.*?\n\}\n(-- \[\[ PYTHON_DATA_END \]\])",
        re.DOTALL,
    )
    updated, count = pattern.subn(rf"\1{replacement_block}\n\2", text, count=1)
    if count != 1:
        raise RuntimeError("Failed to locate the PYTHON_DATA block in RevMplusInfoMythicFrame.lua")
    target.write_text(updated, encoding="utf-8", newline="\n")


def main(argv: Sequence[str]) -> int:
    parser = argparse.ArgumentParser(description="Generate an EU-only Mythic Dashboard dataset.")
    parser.add_argument("input", type=pathlib.Path, help="Path to a JSON or CSV export containing Mythic+ scores.")
    parser.add_argument("--region", default="EU", help="Region label to display in the addon. Default: EU")
    parser.add_argument("--source", default="Raider.IO", help="Source label to display in the addon.")
    parser.add_argument(
        "--data-time",
        default=dt.datetime.now().strftime("%Y.%m.%d %H:%M"),
        help="Display timestamp written into the Lua block.",
    )
    parser.add_argument(
        "--target",
        type=pathlib.Path,
        default=TARGET,
        help="Lua file to patch. Defaults to RevMplusInfoMythicFrame.lua",
    )
    parser.add_argument(
        "--print-only",
        action="store_true",
        help="Print the generated Lua block without patching the target file.",
    )
    args = parser.parse_args(argv)

    region = normalize_region(args.region)
    scores = load_scores(args.input, region)
    if not scores:
        raise SystemExit(f"No usable scores found for region {region} in {args.input}")

    rank_table = build_rank_table(scores)
    replacement_block = render_lua_block(rank_table, len(scores), region, args.source, args.data_time)

    if args.print_only:
        print(replacement_block)
        return 0

    patch_target(args.target, replacement_block)
    print(f"Patched {args.target} with {len(scores)} {region} scores.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
