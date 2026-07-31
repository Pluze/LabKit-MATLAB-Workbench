# Repository Skills

Each directory owns one LabKit-specific agent workflow:

- `SKILL.md` defines activation boundaries and procedure.
- `manifest.yaml` declares stable identity and dependencies.
- `evals.json`, when present, records lightweight positive and negative
  activation examples.

Run `python .github/scripts/validate_agent_skills.py` after changing a Skill.
Model-scored evaluation remains a review aid rather than a required local or
CI dependency.
