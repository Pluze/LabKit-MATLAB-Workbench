# Repository Skills

Each directory owns one LabKit-specific agent workflow:

- `SKILL.md` defines activation boundaries and procedure.
- `agents/openai.yaml` defines the Codex UI name and invocation prompt.
- `evals.json` records positive and negative activation examples.
- `activation-evals.json` records only meaningful cross-Skill collisions and
  exclusions; it is not a catalog of every possible combination.

Run `python .github/scripts/validate_agent_skills.py` after changing a Skill.
Every immediate non-hidden directory is a Skill owner and must contain its
`SKILL.md`; generated `__pycache__` directories are excluded. The validator
checks entry points, metadata, local links, literal current-manual paths,
backticked `labkit-*` Skill routes,
and evaluation contracts deterministically. These checks establish structural
consistency, not whether a model follows the guidance or chooses the correct
workflow. Review activation examples against the affected procedure as well.
Model-scored forward evaluation remains a review aid rather than a required
local or CI dependency.

Write each description from its positive task scope and route adjacent work to
its actual owner. Balanced activation evals carry the deterministic positive
and negative boundary; no fixed prohibition phrase is required in prose.
