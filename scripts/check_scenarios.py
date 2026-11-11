#!/usr/bin/env python3
"""Check the scenario IDs attached to ERT and unittest definitions."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ID = r"@[A-Z]+[0-9]+"
SCENARIO = re.compile(r"((?:^[ \t]*@[^\n]+\n)*)^[ \t]*Scenario(?: Outline)?:", re.MULTILINE)
TEST_MARKERS = (
    ("test/*.el", r"^;;"),
    ("test/test_*.py", r"^ +#"),
)


def check():
    scenarios = {}
    errors = []
    for path in sorted((ROOT / "features").glob("*.feature")):
        for match in SCENARIO.finditer(path.read_text(encoding="utf-8")):
            tags = match[1].split()
            status = set(tags) & {"@automated", "@manual"}
            ids = [tag for tag in tags if re.fullmatch(ID, tag)]
            if len(ids) != 1 or len(status) != 1:
                errors.append(f"{path.name}: scenario needs one ID and one coverage status")
                continue
            scenario = ids[0]
            if scenario in scenarios:
                errors.append(f"{path.name}: duplicate scenario {scenario}")
            scenarios[scenario] = status.pop()

    tested = set()
    for pattern, comment in TEST_MARKERS:
        for path in ROOT.glob(pattern):
            test_definition = r"\(ert-deftest\s" if path.suffix == ".el" else r" +def test_"
            annotated_test = re.compile(
                rf"{comment} +((?:{ID} *)+)\n{test_definition}", re.MULTILINE
            )
            for match in annotated_test.finditer(path.read_text(encoding="utf-8")):
                for scenario in match[1].split():
                    if scenarios.get(scenario) != "@automated":
                        errors.append(f"{path.name}: {scenario} is unknown or not automated")
                    tested.add(scenario)

    missing = sorted(s for s, status in scenarios.items() if status == "@automated" and s not in tested)
    errors.extend(f"{scenario}: missing an annotated test" for scenario in missing)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"{len(tested)} automated scenarios have tests")
    return 0


if __name__ == "__main__":
    sys.exit(check())
