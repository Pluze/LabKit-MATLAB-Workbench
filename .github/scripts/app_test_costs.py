"""Refresh scheduling hints from complete successful App JUnit reports."""
import argparse
import json
import math
from pathlib import Path
import statistics
import xml.etree.ElementTree as ET


def collect_costs(paths):
    observations = {}
    for path in paths:
        root = ET.parse(path).getroot()
        cases = list(root.iter("testcase"))
        invalid = any(True for tag in ("failure", "error", "skipped") for _ in root.iter(tag))
        if not cases or invalid:
            raise ValueError("Use complete, successful JUnit reports without skipped evidence")
        for case in cases:
            identity = case.attrib["classname"] + "/" + case.attrib["name"]
            seconds = float(case.attrib["time"])
            if not math.isfinite(seconds) or seconds <= 0:
                raise ValueError("Test costs must be finite positive durations")
            observations.setdefault(identity, []).append(seconds)
    if not observations:
        raise ValueError("No test cost observations")
    return [{"id": key, "seconds": max(0.000001, round(statistics.median(values), 6))}
            for key, values in sorted(observations.items())]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--junit", type=Path, nargs="+", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    costs = collect_costs(args.junit)
    args.output.write_text("[\n" + ",\n".join(
        "  " + json.dumps(row, sort_keys=True) for row in costs) + "\n]\n", encoding="utf-8")
    print(f"Wrote {len(costs)} scheduling hints to {args.output}")


if __name__ == "__main__":
    main()
