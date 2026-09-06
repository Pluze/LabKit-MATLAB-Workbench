# Framework Compatibility Contracts

```labkit-page
id: develop-framework-compatibility-contracts
type: reference
audience: app-developer
summary: Declare and check the LabKit facade versions an app supports before startup without downloading or changing installed code.
```

[App Framework](../README.md) | [API reference](../../../reference/README.md) | [App development](../../app-authoring/app-development.md)

`labkit.contract` lets an app state which LabKit API versions it supports and check those requirements before startup. It compares versions already present in this repository; it does not download, install, or update code.

This is part of the documented App Framework surface. The MATLAB namespace remains `labkit.contract` because it checks UI and domain facades alike; it is not an App metadata registry or a UI-only helper.

## Typical Use

A `labkit.app.Definition` owns the App's requirements. Native startup checks that declaration before creating the interface; the thin entry point does not repeat the check.

```matlab
requirements = labkit.contract.requirements( ...
    "app", ">=3 <4", "image", ">=2 <3");
% Pass requirements as Requirements when constructing the App Definition.
```

For a standalone computation, check the consumed facade before calling it:

<!-- labkit-runnable-example -->
```matlab
requirements = labkit.contract.requirements("image", ">=2 <3");
labkit.contract.assertRequirements("example_analysis", requirements);
```

If all requirements are compatible, `assertRequirements` returns without a value. Otherwise it throws `example_analysis:IncompatibleLabKit` with one message for each incompatible module.

## Choose a Function

| Task | Function |
| --- | --- |
| Build a requirement structure | [`labkit.contract.requirements`](../../../reference/api/labkit/contract/requirements.html) |
| Inspect compatibility without throwing | [`labkit.contract.checkRequirements`](../../../reference/api/labkit/contract/checkRequirements.html) |
| Stop startup when requirements fail | [`labkit.contract.assertRequirements`](../../../reference/api/labkit/contract/assertRequirements.html) |
| Create the structure returned by a module's `version` function | [`labkit.contract.versionInfo`](../../../reference/api/labkit/contract/versionInfo.html) |

## Version Ranges

A range contains one or more whitespace-separated constraints. Supported operators are `<`, `<=`, `>`, `>=`, `=`, and `==`:

```matlab
">=7 <8"       % 7.x releases
">=2.1 <=2.4" % from 2.1 through 2.4, inclusive
"=1.3.0"       % exactly 1.3.0
```

Versions may contain one, two, or three numeric components. Missing components are treated as zero during comparison, so `6`, `6.0`, and `6.0.0` compare as the same version.

Facade names may be short, such as `"thermal"`, or include the prefix, such as `"labkit.thermal"`. Names are normalized to lowercase without the prefix. Listing the same facade twice in one requirement structure is an error.

## How Compatibility Is Decided

Each module's `version` function returns a structure like this:

```matlab
info = labkit.thermal.version()
```

| Field | Meaning |
| --- | --- |
| `name` | Full module name, such as `"labkit.thermal"` |
| `facade` | Short normalized name, such as `"thermal"` |
| `current` | Current API version |
| `compatible` | One or more requirement ranges implemented by this version |
| `status` | `"stable"`, `"experimental"`, or `"deprecated"` |
| `notes` | Short description of the module contract |

A requirement passes only when both conditions are true:

1. The module's `current` version falls inside the app's requested range.
2. The requested range overlaps at least one range in the module's `compatible` list.

The second check prevents a current version number from appearing acceptable when the installed implementation does not advertise the requested contract.

## Inspecting a Compatibility Report

Use `checkRequirements` when a caller should decide how to display or handle a failure:

```matlab
req = labkit.contract.requirements("thermal", ">=1 <2");
report = labkit.contract.checkRequirements(req);

if ~report.ok
    disp(report.message)
end
```

The returned structure contains:

| Field | Meaning |
| --- | --- |
| `ok` | True when every requirement passes |
| `failures` | One structure per failed requirement |
| `message` | Success text or newline-separated failure explanations |

Each failure records the normalized `facade`, the `required` range, the module's advertised `available` ranges, and a readable `message`. An unknown facade has an empty `available` array.

## Supplying Version Information Explicitly

`checkRequirements` normally queries the installed App SDK, DTA, RHS, biosignal, image, thermal, and Mark-10 modules. Diagnostic code can pass an explicit version structure instead:

```matlab
available = labkit.contract.versionInfo( ...
    "image", "4.1.0", ">=4 <5", "stable", ...
    "Image file IO and processing functions.");

req = labkit.contract.requirements("image", ">=4.0 <5");
report = labkit.contract.checkRequirements(req, available);
```

This form is useful for checking a proposed version declaration without changing the installed module.

## Related Topics

- [App development](../../app-authoring/app-development.md) explains how one App definition owns facade requirements and product version metadata.
- [Architecture](../../app-authoring/architecture.md) describes the public LabKit modules that can appear in a requirement list.
- [Changes](../../../changes/README.md) records API version and compatibility changes.
