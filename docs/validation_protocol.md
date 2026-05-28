# Validation Protocol

Behavior-preserving refactors should compare old and new outputs for the same DTA files.

Default numerical tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerance only for interpolation or plotting-only aligned data.
