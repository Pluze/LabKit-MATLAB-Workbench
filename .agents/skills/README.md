# Repository Skills

Each directory owns one LabKit-specific agent workflow:

- `SKILL.md` defines activation boundaries and procedure.
- `agents/openai.yaml` defines the Codex UI name and invocation prompt.
- `evals.json` records positive and negative activation examples.
- `activation-evals.json` records only meaningful cross-Skill collisions and
  exclusions; it is not a catalog of every possible combination.

Run `python .github/scripts/validate_agent_skills.py` after changing a Skill.
The validator checks metadata and evaluation contracts deterministically.
Model-scored forward evaluation remains a review aid rather than a required
local or CI dependency.

Write each description from its positive task scope and route adjacent work to
its actual owner. Balanced activation evals carry the deterministic positive
and negative boundary; no fixed prohibition phrase is required in prose.
