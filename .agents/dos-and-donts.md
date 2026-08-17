# Working Dos and Don'ts

This file is the repository's compact experience reservoir. After each
meaningful checkpoint, record only a high-value lesson that would save future
investigation, retry, or design cost. Let lessons accumulate and survive
repeated use before promoting them; this is not a chronological work log or a
second architecture guide.

## Record, promote, and compress

- Add only a lesson whose rediscovery would cost meaningful investigation or
  retry time. Record the durable cause and better practice, never a transcript,
  successful command, transient failure, version, or one-off filename.
- Merge with an existing lesson before adding another. Do not promote a new
  observation immediately merely because a destination exists. After it has
  accumulated supporting cases and remained useful over time, promote policy
  to `AGENTS.md`, procedure to a skill, enforceable behavior to a test, or
  product/API meaning to source help or a manual.
- When promotion is proven, merge or remove the reservoir copy. Regularly
  compress related lessons into fewer principle-first statements and delete
  stale, duplicated, disproven, or low-value detail.

## Incubating lessons

- When the same ownership boundary needs a second local workaround, stop
  extending the patch chain. Reconstruct the complete entry-to-owner call
  graph, state the invariant that should make resolution deterministic, and
  replace the boundary coherently before spending more time on symptoms.
- When an action promises a physical device state change, a successful
  software-only approximation is a contract violation, not graceful
  degradation. If the device operation cannot be sent and verified, report
  the unavailable capability and leave readings, retained data, analysis, and
  exports unchanged; expose any legitimate post-processing transform as a
  separately named workflow.
- When read-only device traffic succeeds but a status or control request is
  silent, do not infer a parser or timeout defect from connectivity alone.
  Distinguish OS enumeration, port availability, data-channel support,
  operating mode, licensed capability, and command authorization, then compare
  an independent raw request with the authoritative protocol before changing
  transport timing or response handling.
