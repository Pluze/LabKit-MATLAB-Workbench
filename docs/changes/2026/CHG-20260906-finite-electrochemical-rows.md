# Remove nonfinite electrochemical rows consistently

```labkit-change
id: CHG-20260906-finite-electrochemical-rows
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_CIC_app | 1.7.1 -> 1.7.2
component: labkit_CSC_app | 1.7.1 -> 1.7.2
```

## Why

CIC documented finite input cleaning but only removed NaN rows. Infinite values could invalidate interpolation while leaving the calculation marked successful. CSC likewise retained infinite rows and then skipped adjacent integration segments, understating charge.

## What changed

Both calculations remove a row when any required time, voltage, or current value is nonfinite. Interpolation and integration use the remaining adjacent samples, following the existing missing-row policy. Minimum sample requirements, finite-data formulas, units, selectors, and result fields remain unchanged.

## Impact

Partially invalid recordings now use their finite rows consistently.

## Compatibility and limits

Bridging removed rows is the existing missing-data policy, not evidence that a recording gap is scientifically acceptable; users must inspect acquisition gaps and pulse or cycle support. Recordings with insufficient remaining points still return a failed result.
