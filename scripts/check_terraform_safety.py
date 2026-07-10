#!/usr/bin/env python3
"""Reject unsafe Terraform destroy paths and verify the reviewed-plan workflow."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECT_DESTROY_PATTERNS = (
    re.compile(r"\b(?:terraform|tofu)(?:\s+-[^\s]+)*\s+destroy\b"),
    re.compile(r"(?:\$\(TF\)|\$\{TF\}|\$TF)\s+destroy\b"),
)


def executable_lines(path: Path) -> list[tuple[int, str]]:
    lines: list[tuple[int, str]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if path.name == "Makefile":
            if not line.startswith("\t"):
                continue
        elif not stripped or stripped.startswith("#"):
            continue
        lines.append((number, line))
    return lines


def find_direct_destroy() -> list[str]:
    candidates = [ROOT / "Makefile"]
    candidates.extend(sorted((ROOT / "scripts").rglob("*.sh")))

    findings: list[str] = []
    for path in candidates:
        if not path.exists():
            continue
        for number, line in executable_lines(path):
            if any(pattern.search(line) for pattern in DIRECT_DESTROY_PATTERNS):
                findings.append(f"{path.relative_to(ROOT)}:{number}: {line.strip()}")
    return findings


def dry_run_destroy_workflow() -> str:
    environment = os.environ.copy()
    # A generic ambient TARGET must never silently become a Terraform -target.
    environment["TARGET"] = "ambient-target-must-be-ignored"
    result = subprocess.run(
        [
            "make",
            "--no-print-directory",
            "-n",
            "template-tf-infra-destroy",
            "TF_ENV=stage",
            "TF_STACK=ec2",
        ],
        cwd=ROOT,
        env=environment,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr or result.stdout)
    return result.stdout


def verify_destroy_workflow(output: str) -> list[str]:
    errors: list[str] = []
    required_in_order = (
        'plan -destroy -out="terraform.destroy.tfplan"',
        'show -no-color "terraform.destroy.tfplan"',
        "Type 'destroy stage/ec2'",
        'apply "terraform.destroy.tfplan"',
    )

    position = -1
    for fragment in required_in_order:
        next_position = output.find(fragment, position + 1)
        if next_position < 0:
            errors.append(f"destroy dry-run is missing: {fragment}")
            continue
        if next_position <= position:
            errors.append(f"destroy dry-run is out of order at: {fragment}")
        position = next_position

    if "-target=module.ambient-target-must-be-ignored" in output:
        errors.append("ambient TARGET leaked into the Terraform destroy plan")

    return errors


def main() -> int:
    errors = find_direct_destroy()
    try:
        errors.extend(verify_destroy_workflow(dry_run_destroy_workflow()))
    except RuntimeError as exc:
        errors.append(f"destroy workflow dry-run failed: {exc}")

    if errors:
        print("Terraform safety checks failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Terraform destroy workflow uses a displayed, confirmed, saved plan artifact.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
