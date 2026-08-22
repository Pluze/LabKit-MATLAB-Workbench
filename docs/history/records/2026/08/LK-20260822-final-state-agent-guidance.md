# Final-state agent guidance

```labkit-change
id: LK-20260822-final-state-agent-guidance
date: 2026-08-22
sequence: 190
type: chore
compatibility: compatible
scope: Agent governance
scope: Final artifact provenance
```

## Context

Repository agent guidance is loaded across many tasks, so durable rules need one authoritative owner and final artifacts need to remain understandable without the working conversation.

## Decision and rationale

Agent guidance now distinguishes current invariants and required facts from session-only control data. Corrections become repository rules only after repeated current evidence, and titles, comments, documentation, Git metadata, release text, and handoffs are derived from the accepted baseline and final result.

## Changes

The root constitution owns final-artifact provenance and reader relevance. Repository Skill descriptions use positive task scope and route adjacent work to its owner, while balanced activation evals retain deterministic boundary coverage. The general experience reservoir and empty migration ledger were retired; an active migration ledger is created only while owned retirement work exists. Current diagnostic comments and Mark-10 troubleshooting guidance now state their enduring contracts directly.

## User and data impact

LabKit product behavior, scientific results, saved data, and public APIs are unchanged. Future repository artifacts should contain less development-session residue while retaining safety, compatibility, scientific, and migration facts that readers need.

## Compatibility and migration

The change is compatible and requires no product or data migration. Active architecture or compatibility retirement work can still create `.agents/migration_guide.md` for its bounded lifetime.

## Validation

Repository Skill contracts, their validator unit tests, MATLAB code analysis, deterministic documentation generation, and the App SDK diagnostic event-stream evidence closure validate the changed owners and preserved runtime behavior.

## Evidence

The Skill validator accepted all 11 repository Skills; its six unit tests passed. Code analysis reported zero issues, suppressions, compatibility recommendations, or unreviewed runtime calls. Documentation produced identical 411-file trees, and all 88 selected App SDK diagnostic specifications passed.

## Known limitations and follow-up

Semantic residue detection remains a reader judgment; exact text searches can assist but cannot prove that every paraphrase is absent.
