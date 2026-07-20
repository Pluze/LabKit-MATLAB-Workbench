# UI explicit-contract authoring ergonomics gate

Status: active production gate, established 2026-07-19.

The replacement is an SDK. Internal framework size is not an acceptance
metric; repeated App wiring and the number of concepts required on the paved
road are. `UiAuthoringErgonomicsTest` protects the first executable budgets.

| Author task | Current production path | Gate |
| --- | --- | --- |
| Static App | `Application` plus `Layout` | No Command, presenter, project, or capability list |
| Ordinary state field | `Layout.field(..., Bind=path)` | No Command and no presenter operation |
| Business-effect control | One `Command`, callback, and direct Layout reference | No duplicate Application command registry |
| Simple project | `ProjectContract()` | Version 1 scalar-struct create/validate defaults |
| Context capabilities | Omit `Capabilities` | Standard path has no synchronized allow-list |
| Framework log | `context.appendStatus(message)` | No false App-state return value |
| Standard file collection | `filePanel(..., Bind=..., SelectionBind=...)` | No Command or presenter; runtime owns records, selection, and project rebasing |

Chrono Overlay is the first real migrated App:

| Chrono author surface | Runtime V2 | Explicit contract |
| --- | ---: | ---: |
| Definition code lines | 20 | 20 |
| Layout code lines | 73 | 33 |
| Action/callback code lines | 149 | 38 |
| Presenter code lines | 55 | 15 |
| App callbacks | 5 | 1 |
| App-authored presenter operations | 5 | 2 |

Counts exclude blank/comment-only MATLAB lines and use commit `5a87bdd2` as
the Runtime V2 baseline. The remaining callback is the scientific CSV/result
export. Runtime owns file add/remove/clear, stable source identities,
selection, transient session rebuild, project source portability, binding
updates, and native component reconciliation. One renderer receives the two
declared axes in order.

This closes the one-plot and one-result-package rows. Project save/restore is
covered through the declared `ProjectContract` without App menu code; the
production project menu and recovery UX remain a framework item. T-Test
Wizard and Curvature or Video Marker next supply the table/workspace and
interaction/resource comparisons.

Public capability extensions require either repeated need in at least two Apps
or one framework-owned lifecycle/consistency problem. A capability is not
accepted merely because it can be generalized.
