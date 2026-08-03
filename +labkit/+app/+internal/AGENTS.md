# App SDK Internal Ownership

`labkit.app.internal` is a private composition boundary, not a miscellaneous
helper namespace. The package root contains no MATLAB implementation files;
every type belongs to one named subsystem.

The dependency direction is:

```text
Definition / CallbackContext
    |-- contract -> immutable layout, signal, and compiled plan
    `-- runtime  -> transaction ordering and callback capabilities
                     |-- diagnostics
                     |-- project / source / result / resource
                     |-- artifact
                     `-- native -> interaction + MATLAB handles
```

Lower owners never look up or invoke `RuntimeKernel`. A lifecycle may receive
one narrow callback from its caller, but must not acquire the caller or a
general service bag.

- Put immutable definition compilation under `+contract`; it must not acquire
  runtime state, native handles, persistence, or diagnostics.
- Put transaction ordering, state-path mutation, callback construction, and
  runtime factories under `+runtime`.
- Put concrete MATLAB window behavior under `+native` and keep the platform
  adapter as the semantic reconciliation boundary, not the owner of every
  window lifecycle.
- Put artifact naming and scratch-destination policy under `+artifact`.
- Put Runtime-level diagnostic viewing and export coordination under
  `+diagnostics`; keep event, journal, and bundle primitives focused and move
  them only when the move clarifies ownership independently of taxonomy.
- Keep project documents, portable sources, results, resources, and
  interactions with their existing focused owners; when one subsystem needs
  multiple new types, create one semantically named internal subpackage
  instead of adding another root-level bucket.
- `RuntimeKernel` owns transaction order and cross-subsystem commit/rollback.
  It delegates independent storage, export, diagnostics, naming, and native
  lifecycle mechanics rather than implementing them inline.
- `MatlabPlatformAdapter` owns translation between semantic Snapshot
  operations and native components. It delegates independent busy, startup,
  close, acquisition, and utility workflows once they have state or lifecycle
  of their own.
- Split a class-folder method when it is still part of the adapter's semantic
  reconciliation. Extract a separate owner when a workflow has its own state,
  timing, fallback, cleanup, or transaction. File length alone does not decide
  ownership, but a growing file is a signal to make this check before adding
  another inline workflow.
- Do not introduce `misc`, `common`, `utils`, `helpers`, `manager`, or
  `service` buckets. A new internal type names the state or lifecycle it owns,
  has one production caller direction, and is directly testable through that
  owner.
- Do not add MATLAB files directly to this package root. Extend the narrowest
  existing subsystem, or update the architecture guardrail together with a
  justified new cohesive subsystem.

Moving code is not itself an ownership improvement. Preserve transaction,
rollback, appearance, input, status, diagnostics, and close semantics while
extracting one complete responsibility.
