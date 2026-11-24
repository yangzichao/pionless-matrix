#!/usr/bin/env python3
"""Print pass counts per prompt and host from a results.jsonl file.

With a second file, also print the prompts whose pass rate changed,
for comparing a new run against a baseline.
"""

import json
import sys
from collections import defaultdict


def load_pass_counts(results_path):
    counts = defaultdict(lambda: [0, 0, []])
    with open(results_path, encoding="utf-8") as results:
        for line in results:
            row = json.loads(line)
            entry = counts[(row["id"], row["host"])]
            entry[0] += row["passed"]
            entry[1] += 1
            if not row["passed"]:
                entry[2].append(row["skills_loaded"])
    return counts


def print_table(counts):
    totals = defaultdict(lambda: [0, 0])
    for (prompt_id, host), (passed, total, failures) in sorted(counts.items()):
        totals[host][0] += passed
        totals[host][1] += total
        failure_note = f"  failed runs loaded {failures}" if failures else ""
        print(f"{prompt_id:<16} {host:<11} {passed}/{total}{failure_note}")
    print()
    for host, (passed, total) in sorted(totals.items()):
        print(f"{host:<11} {passed}/{total} passed")


def print_changes(baseline_counts, new_counts):
    # Compare pass rates only for prompts present in both runs, so a partial
    # re-run or a different --runs count does not show up as a change.
    print("\npass rate changed against baseline:")
    changed = False
    for key in sorted(set(baseline_counts) & set(new_counts)):
        before = baseline_counts[key]
        after = new_counts[key]
        if before[0] * after[1] != after[0] * before[1]:
            changed = True
            print(f"  {key[0]:<16} {key[1]:<11} {before[0]}/{before[1]} -> {after[0]}/{after[1]}")
    if not changed:
        print("  none")


def main():
    if len(sys.argv) not in (2, 3):
        print("usage: summarize_results.py <results.jsonl> [<baseline results.jsonl>]")
        return 2
    new_counts = load_pass_counts(sys.argv[1])
    print_table(new_counts)
    if len(sys.argv) == 3:
        print_changes(load_pass_counts(sys.argv[2]), new_counts)
    return 0


if __name__ == "__main__":
    sys.exit(main())
