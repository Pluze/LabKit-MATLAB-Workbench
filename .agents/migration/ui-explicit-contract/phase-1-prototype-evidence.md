# Phase 1 representation prototype evidence

| Representation | Public files | Deterministic Apps | Strict failures |
| --- | ---: | ---: | ---: |
| Sealed value classes | 5 | 3/3 | 3/3 |
| Opaque function values | 15 | 3/3 | 3/3 |

Decision: `sealed-immutable-value-classes`.

Both forms can reject invalid contracts and compile deterministic plans. Value methods are discoverable and compose without a large global function vocabulary. MATLAB functions() exposes closure workspaces, so function-handle tokens are conventionally opaque rather than representation-safe.

GUI-free compile medians (value/opaque, milliseconds): T-Test Wizard 0.063/0.122; Curvature Measurement 0.066/0.115; Video Marker 0.082/0.112.

Distinct framework-seam lines (current/value/opaque): 564/52/48.

Opaque closure backing state visible through MATLAB `functions`: true.
