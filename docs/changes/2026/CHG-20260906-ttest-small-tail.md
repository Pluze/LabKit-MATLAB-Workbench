# Preserve small Student-t tail probabilities

```labkit-change
id: CHG-20260906-ttest-small-tail
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_TTestWizard_app | 1.5.0 -> 1.5.1
```

## Why

Subtracting an almost-one cumulative probability from one erased small representable p-values and could make a two-sided result depend on group order.

## What changed

The calculation retains lower and upper tails from the incomplete-beta evaluation and selects the required tail directly.

## Impact

Large finite statistics retain representable small p-values, and two-sided tests preserve sign symmetry. Test methods, degrees of freedom, effect estimates, and ordinary significance decisions retain their existing definitions.

## Compatibility and limits

Values below floating-point range can still underflow. Numerical stability does not establish independence, replication, or suitability of the chosen statistical test.
