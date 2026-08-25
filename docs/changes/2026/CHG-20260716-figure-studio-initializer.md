# Figure Studio names its post-layout initialization capability

```labkit-change
id: CHG-20260716-figure-studio-initializer
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FigureStudio_app | 0.2.4 -> 0.2.5
```

## Why

Figure Studio was the only public App with a generic `startup.m` file. Its definition already declared the function through Runtime V2's optional `Start` capability, but the filename obscured who invoked it and made the function look like an independent lifecycle entrypoint.

### Accepted choice

Keep the Runtime-owned `Start` hook because Figure Studio genuinely needs a post-layout phase: it consumes an optional axes handoff, resolves the managed preview axes, and registers a cleanup-owned resize resource. Rename the App callback to `initializeWorkbench` so its capability and invocation boundary are explicit. Do not move GUI/service work into the GUI-free session factory or reintroduce App-owned timers and readiness state.

## What changed

- Renamed the Start callback from generic `startup` to `initializeWorkbench` and declared the new handle in `definition`.
- Documented the callback timing and the request, preview, resource, dialog, workflow, and debug services supplied by Runtime V2.
- Tightened the App structure guardrail so compact Apps cannot add a generic `startup.m` file outside their declared capability vocabulary.
- Advanced the Figure Studio App version to 0.2.5.

## Impact

Normal launch, default output folder selection, popout axes handoff, source style adoption, preview canvas resize behavior, debug logging, project data, and exports are unchanged. No project migration is required.

## Compatibility and limits

The public command and Runtime definition contract are unchanged. `startup` was an App-internal callback referenced only by the definition; callers should launch the App rather than invoke either callback directly.

### Remaining limits

The Start capability remains necessary for post-layout resources; removing it would require a different framework service phase rather than a file move. App and agent guidance still need a repository-wide terminology audit.
