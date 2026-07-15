# Contract API

[Public API index](README.md) · [App development](../development/app-development.md)

`labkit.contract` checks whether an app's required LabKit facade versions are
available before launch. It is a same-repository compatibility guardrail, not
a package manager.

## `requirements`

```matlab
req = labkit.contract.requirements(facade1, range1, facade2, range2, ...)
```

Provide facade/range pairs such as `"ui", ">=6 <7"`. Facade names may be short
or begin with `labkit.`. Ranges contain whitespace-separated semantic-version
constraints using `<`, `<=`, `>`, `>=`, `=`, or `==`.

The returned struct has `type="labkit.requirements"` and a `facades` struct
array with `facade` and `range` fields. Duplicate facade names and malformed
pairs are errors.

## `checkRequirements`

```matlab
report = labkit.contract.checkRequirements(req)
report = labkit.contract.checkRequirements(req, versions)
```

When `versions` is omitted, LabKit queries the current UI, DTA, RHS, biosignal,
image, and thermal facade versions. The result contains:

| Field | Meaning |
| --- | --- |
| `ok` | True when every required range matches the current and advertised facade contracts. |
| `failures` | Struct array with `facade`, `required`, `available`, and `message`. |
| `message` | One success message or newline-separated incompatibility details. |

Pass an explicit version struct array only for tests or diagnostics.

## `assertRequirements`

```matlab
labkit.contract.assertRequirements(appName, req)
labkit.contract.assertRequirements(appName, req, versions)
```

This is the throwing form of `checkRequirements`. It returns no value. On
failure it throws `<appName>:IncompatibleLabKit` with the report details.
Public app launch commands call it before constructing the GUI.

## `versionInfo`

```matlab
info = labkit.contract.versionInfo( ...
    facade, current, compatible, status, notes)
```

`compatible` is a string array of implemented ranges. `status` is `"stable"`,
`"deprecated"`, or `"experimental"`. The returned struct contains `name`,
`facade`, `current`, `compatible`, `status`, and `notes`.

Facade-owned `version.m` functions use this helper; apps normally consume the
result through requirement checks rather than constructing version records.

## Example

```matlab
function req = requirements()
    req = labkit.contract.requirements( ...
        "ui", ">=6 <7", ...
        "image", ">=4 <5");
end

labkit.contract.assertRequirements("labkit_Example_app", requirements())
```

## Related Topics

- [Architecture: UI boundary](../development/architecture.md#ui-boundary)
- [App development: version and requirements](../development/app-development.md#version-and-requirements)
