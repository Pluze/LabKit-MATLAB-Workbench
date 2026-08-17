# Repository Skills

Each directory owns one LabKit-specific agent workflow:

- `SKILL.md` defines activation boundaries and procedure.
- `agents/openai.yaml` defines the Codex UI name and invocation prompt.
- `manifest.yaml` declares stable identity and repository-audited workflow
  dependencies. Codex does not load these dependencies automatically, so every
  dependency must also have an explicit conditional route in `SKILL.md`.
- `evals.json` records positive and negative activation examples.
- `activation-evals.json` records cross-Skill activation and exclusion cases.

Run `python .github/scripts/validate_agent_skills.py` after changing a Skill.
The validator checks metadata and evaluation coverage deterministically.
Model-scored forward evaluation remains a review aid rather than a required
local or CI dependency.
