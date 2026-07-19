# Phase 1 representation prototype evidence

| Representation | Public files | Deterministic Apps | Strict failures |
| --- | ---: | ---: | ---: |
| Sealed value classes | 5 | 3/3 | 5/5 |
| Opaque function values | 15 | 3/3 | 5/5 |

Decision: `sealed-immutable-value-classes`.

Both forms can reject invalid contracts and compile deterministic plans. Value methods are discoverable and compose without a large global function vocabulary. MATLAB functions() exposes closure workspaces, so function-handle tokens are conventionally opaque rather than representation-safe.

GUI-free compile medians (value/opaque, milliseconds): T-Test Wizard 0.277/0.492; Curvature Measurement 0.290/0.147; Video Marker 0.264/0.120.

Prototype-covered seam lines (current/value/opaque): 506/52/48.

Opaque closure backing state visible through MATLAB `functions`: true.
