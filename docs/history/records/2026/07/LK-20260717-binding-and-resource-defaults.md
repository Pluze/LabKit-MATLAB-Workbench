# Binding-only controls and default resource cleanup

```labkit-change
id: LK-20260717-binding-and-resource-defaults
date: 2026-07-17
sequence: 122
type: refactor
compatibility: compatible
component: `labkit.ui` | `7.4.5 -> 7.4.6`
component: `labkit_VideoMarker_app` | `1.5.4 -> 1.5.5`
scope: Runtime V2 action registration
scope: Runtime V2 resource ownership
```

## Context

Runtime V2 already supported controls whose complete behavior is writing one
bound state path, but Video Marker still registered an empty action for its
skeleton-preset selector. The private resource registry also had a default
cleanup policy, while the injected App service required every call to supply a
fourth cleanup function. Video Marker therefore kept a second empty function
for its plain decoded-video resource.

## Decision and rationale

Use the existing binding-only contract for state-only controls and expose the
resource registry's existing default cleanup through the injected service.
Apps should declare an action only when a user event has workflow behavior
beyond committing the bound value. Plain structs and values require no
App-owned cleanup placeholder.

## Changes

- Removed Video Marker's empty skeleton-preset change action and left the
  dropdown as a direct session binding.
- Made the injected `services.resources.set(scope,id,value)` form select the
  Runtime's default cleanup, while retaining the optional fourth custom
  cleanup function.
- Removed Video Marker's empty video-resource cleanup function.
- Added Runtime GUI coverage for binding-only state commits and resources
  registered without a custom cleanup.

## User and data impact

There is no workflow, scientific, project-data, or saved-file change. Selecting
a skeleton preset still updates the session immediately, and **Use preset**
still performs the only durable skeleton edit. Video cache replacement and
session cleanup retain the same observable behavior.

## Compatibility and migration

The change is source-compatible. Existing four-argument resource registration
continues to use the supplied cleanup function. No project migration is
required.

## Validation

The focused Runtime V2 GUI test exercises both service forms and proves that a
binding without `Event` commits state without invoking an App action. Video
Marker structure and targeted behavior tests cover the simplified definition.

## Evidence

- [Runtime and Lifecycle](../../../../framework/guides/runtime.md) documents bound
  controls and injected resource ownership.
- [Video Marker](../../../../apps/image-measurement/video-marker/README.md)
  describes the preset and decoded-video resource behavior.

## Known limitations and follow-up

Other bound events still require App actions when they normalize values,
invalidate results, update previews, or log workflow changes. They should be
reviewed by behavior rather than removed merely because their handlers are
short.
