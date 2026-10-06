# App SDK Internal Ownership

`labkit.app.internal` is a private composition boundary, not a miscellaneous
helper namespace. The package root contains no MATLAB implementation files;
every type belongs to one named subsystem.

The dependency direction is:

```text
Definition / CallbackContext
    |-- contract -> immutable layout, signal, and compiled plan
    |-- discovery -> App descriptors, scanning, path activation, invocation
    |-- filesystem -> lexical absolute path identity
    |-- identity -> opaque process-unique identifiers
    `-- runtime  -> transaction ordering and callback capabilities
                     |-- diagnostics
                     |-- source / resource
                     `-- native -> interaction + MATLAB handles
```

Contract, source, resource, and journal owners do
not look up or invoke `RuntimeKernel`. The native adapter and Session Log
viewer are the two explicit UI callback edges: they may receive the Runtime at
construction and call its named boundary methods, but must not expose it,
redistribute it, or turn it into a general service bag. A narrower lifecycle
receives one callback from its caller rather than acquiring the caller.

- Put immutable definition compilation under `+contract`; it must not acquire
  runtime state, native handles, persistence, or diagnostics.
- Put transaction ordering, state-path mutation, callback construction, and
  runtime factories under `+runtime`.
- Put concrete MATLAB window behavior under `+native` and keep the platform
  adapter as the semantic reconciliation boundary, not the owner of every
  window lifecycle.
- Keep `+launcher/dispatch.m` as entry routing only. Put App descriptors,
  scanning, path activation, and revalidated dynamic App invocation under
  `+discovery`; Launcher, documentation consumers, and Plot-to-App handoffs may
  use that GUI-free boundary. Keep request parsing, documentation resolution,
  metadata tables, native view construction, stateful controller callbacks,
  and fixed maintainer-tool adapters under `+launcher`. Plot-to-App handoffs
  must not acquire a Launcher window, global Launcher callback, or app-specific
  Launcher dependency.
- Keep `+filesystem` and `+identity` as leaf private primitives. They use
  MATLAB language and Base MATLAB only, expose no App-facing API, and own
  lexical path identity and opaque identifiers respectively.
  Do not turn them into a generic utility bucket or add workflow policy there.
- Put Runtime-level diagnostic viewing and export coordination under
  `+diagnostics`; keep event, journal, and bundle primitives focused and move
  them only when the move clarifies ownership independently of taxonomy.
- Keep runtime sources, resources, and interactions with their focused owners;
  when one subsystem needs
  multiple new types, create one semantically named internal subpackage
  instead of adding another root-level bucket.
- `RuntimeKernel` owns transaction order and cross-subsystem commit/rollback.
  Storage, export, diagnostics, naming, and native lifecycles stay with their
  owners. Keep workflow order readable; file length alone is not a reason to
  split methods or add an owner.
- `MatlabPlatformAdapter` translates semantic Snapshot operations to native
  components. A separate lifecycle owner needs independent state, timing,
  cleanup, or transaction behavior; a forwarding method alone does not.

Internal class names and file decomposition are implementation choices, not
compatibility contracts. Changes must preserve transaction, rollback,
appearance, input, status, diagnostics, and close behavior. Moving code without
removing duplication or clarifying responsibility is not a simplification.
