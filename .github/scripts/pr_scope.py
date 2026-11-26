"""Choose the PR jobs from the complete diff of the tested merge result."""
import re
import subprocess
from pathlib import Path

GOVERNANCE = re.compile(Path(__file__).with_name("agent_governance_text.pattern").read_text().strip())
APP = re.compile(r"(?:apps|tests/specs/apps)/[^/]+/[^/]+/.+\.m")


def validation_scope(paths):
    scope = "policy"
    if not paths:
        return "full"
    for path in paths:
        if path == "README.md" or (path.startswith("docs/") and path.endswith(".md")):
            if scope == "policy":
                scope = "docs"
        elif GOVERNANCE.fullmatch(path):
            continue
        elif APP.fullmatch(path) and Path(path).is_file() and "\n" not in path and "\r" not in path:
            scope = "apps"
        else:
            return "full"
    return scope


def merge_paths():
    raw = subprocess.check_output(["git", "diff", "--no-renames", "--name-only", "-z", "HEAD^1", "HEAD"])
    return [p.decode("utf-8") for p in raw.split(b"\0") if p]


if __name__ == "__main__":
    import sys

    paths = merge_paths()
    scope = validation_scope(paths)
    if len(sys.argv) == 1:
        print(scope)
    elif sys.argv[1:] == ["--app-paths"] and scope == "apps":
        for path in paths:
            if APP.fullmatch(path):
                print(path)
    else:
        raise SystemExit("Expected a focused App diff for --app-paths")
