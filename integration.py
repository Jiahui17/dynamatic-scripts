from enum import Enum
import argparse
import subprocess
import os
import json
import shutil
import re

from argparse import RawTextHelpFormatter

class Tests(Enum):
    ALL = "all"
    CI = "ci"
    SPEC = "spec"
    SHORT = "short"

RESULTS_DIR = "../results_integration"
BASELINE_RESULTS = f"{RESULTS_DIR}/baseline_perf_results.json"
CURRENT_JSON = f"{RESULTS_DIR}/current_perf_results.json"
CURRENT_MD = f"{RESULTS_DIR}/current_perf_results.md"
GEN_PERF_REPORT = "tools/integration/generate_perf_report.py"

os.makedirs(RESULTS_DIR, exist_ok=True)

def generate_baseline():
    print(f"[INFO] Generating new baseline at {BASELINE_RESULTS}")
    subprocess.run(["python3", GEN_PERF_REPORT, "--save", BASELINE_RESULTS])

def generate_comparative_report():
    if not os.path.exists(BASELINE_RESULTS):
        print(f"[WARN] No baseline found at {BASELINE_RESULTS}. Run with --set-baseline first.")
        return

    print("[INFO] Generating comparative report...")
    result = subprocess.run(
        ["python3", GEN_PERF_REPORT, "--save", CURRENT_JSON, "--compare", BASELINE_RESULTS],
        capture_output=True,
        text=True
    )

    with open(CURRENT_JSON) as f:
        current_results = json.load(f)

    # only want performance results for what we just ran
    current_benchmarks = {result["name"] for result in current_results.get("data", [])}

    filtered_lines = []


    # get the performance report from the script output
    for line in result.stdout.splitlines():
        # keep header or separator lines
        if "Benchmarks" not in line:
            filtered_lines.append(line)
            continue

        # get all cells of the row
        m = re.search(r"\| (.*?) \|", line)
        if not m:
            raise RuntimeError("Table parsed incorrectly")
        
        # first cell is benchmark name
        # check if its in the current test suite
        # if so, include in output table
        if m.group(1) in current_benchmarks:
            filtered_lines.append(line)

    with open(CURRENT_MD, "w") as f:
        f.write("\n".join(filtered_lines))


def main():
    parser = argparse.ArgumentParser(
        description=f"""
Run Dynamatic integration tests, and generate a comparative performance report.
Call from inside the dynamatic directory as ../integration.py
Results are saved in result_integration/
If --set-baseline is used, the performance is stored as baseline_perf_results.json
Otherwise, the performance is stored as current_perf_results.json,
and additionally a markdown table is stored in current_perf_results.md,
which compares to the stored baseline.

It is recommened to run --set-baseline with --target all on the main branch,
as the markdown table will filter only to the benchmarks in current_perf_results.json
""".strip(),
        formatter_class=RawTextHelpFormatter
    )

    parser.add_argument(
        "--target",
        type=Tests,
        choices=list(Tests),
        required=True,
        # print the string values of the enums
        metavar="{" + ", ".join(t.value for t in Tests) + "}",
        help="Which set of tests to run"
    )
    
    parser.add_argument(
        "--set-baseline", 
        action="store_true", 
        help="Store this run as the new baseline"
    )

    args = parser.parse_args()

    # map from enum to test targets
    target_map = {
        Tests.ALL: "run-all-integration-tests",
        Tests.CI: "run-ci-integration-tests",
        Tests.SPEC: "run-spec-integration-tests",
        Tests.SHORT: "run-short-integration-tests",
    }
    target = target_map[args.target]


    shutil.rmtree("build/tools/integration/results", ignore_errors=True)
    subprocess.run(["ninja", "-C", "build", target])

    if args.set_baseline:
        generate_baseline()
    else:
        generate_comparative_report()

if __name__ == "__main__":
    main()
    