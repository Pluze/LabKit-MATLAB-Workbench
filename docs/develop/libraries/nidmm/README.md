# NI-DMM Driver Facade

```labkit-page
id: library-nidmm
type: reference
audience: app-developer
summary: Use an end-user-installed NI-DMM driver through one GUI-free, MATLAB-native LabKit boundary.
```

[API reference](../../../reference/README.md) | [NI-DMM Recorder](../../../use/apps/electrical-measurement/ni-dmm-recorder/README.md)

`labkit.nidmm` owns NI digital-multimeter access for public LabKit Apps. App code calls only this facade; the private adapter is the sole production location allowed to touch the fixed NI-DMM .NET API. Vendor objects never cross the facade boundary.

## Runtime Requirement

The operator installs the 64-bit NI-DMM driver with .NET support. LabKit does not download, bundle, or install it. `labkit.nidmm.availability` checks the supported Windows platform and fixed assembly without opening hardware. Missing or incompatible software is returned as structured status; `connect` turns that status into a stable LabKit error instead of allowing a later undefined-class failure.

NI USB-4065 access is Windows-only. The implementation currently targets the NI-DMM .NET API shipped with NI-DMM 18.0 or newer and uses a NI MAX resource name such as `Dev1`. The physical resource is exclusive: one process may own a given DMM at a time.

## Configure And Acquire

```matlab
status = labkit.nidmm.availability();
if ~status.Available
    error(status.Message)
end
connection = labkit.nidmm.connect("Dev1");
cleanup = onCleanup(@() labkit.nidmm.disconnect(connection));
[connection, applied] = labkit.nidmm.configure(connection, ...
    Mode="resistance_4wire", Range=1000, Digits=5.5);
[connection, sample] = labkit.nidmm.readSample(connection);
```

Supported modes are DC and AC voltage, DC and AC current, two-wire resistance, four-wire resistance, and diode. Range is a positive full-scale value in the returned unit or `"auto"`. Automatic mode takes one settling reading, locks the resolved hardware range, and reports it in `applied`. Resolution choices are 4.5, 5.5, and 6.5 digits.

`startSampling` configures hardware-paced multipoint acquisition and a lightweight Base MATLAB timer drains completed readings in batches. It does not consume `backgroundPool`, so the Mark-10 facade may use that worker concurrently. Requested rate is not reported as achieved rate; callers calculate the observed result from retained samples.

Every sample contains its SI unit, applied mode/range/digits, sequence, elapsed time, UTC estimate, host receipt time, and timing uncertainty. The USB-4065 does not provide the shared clock or trigger used by the Mark-10 path. The timestamp is therefore a host-clock estimate based on the NI acquisition start and configured interval, not deterministic hardware synchronization.

## Functions

| Task | Function |
| --- | --- |
| Check runtime | `labkit.nidmm.availability` |
| Open or close a resource | `labkit.nidmm.connect`, `labkit.nidmm.disconnect` |
| Apply mode, range, and resolution | `labkit.nidmm.configure` |
| Read once | `labkit.nidmm.readSample` |
| Start or stop buffered acquisition | `labkit.nidmm.startSampling`, `labkit.nidmm.stopSampling` |
| Inspect compatibility | `labkit.nidmm.version` |

## Concurrency And Limits

Prefer one MATLAB instance with Mark-10 Monitor and NI-DMM Recorder open together. Their transports and sampling mechanisms are independent. If process-level isolation is needed, an operator may open two LabKit launchers from separate MATLAB instances and assign one device to each. Never open the same NI or serial resource in both instances; the second connection should fail as busy. Repository code does not spawn the second MATLAB process.

Check lead placement and safe voltage/current limits before changing modes. Software cannot detect every unsafe wiring condition. Stop acquisition before rewiring or changing configuration.
