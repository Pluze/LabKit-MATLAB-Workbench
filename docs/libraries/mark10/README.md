# Mark-10 Driver

[API reference](../../reference/README.md) | [Mark-10 Monitor](../../apps/force-gauges/mark10-monitor/README.md)

`labkit.mark10` is a GUI-free serial driver for an ESM303 test stand with an
attached Series 5 force gauge. It owns documented ESM303 and GCL2 framing,
capability probing, force/travel decoding, synchronized acquisition with a
safe fallback, settings readback, and zero verification. It never sends stand
motion, limit, cycle, or automatic `SAVE` commands.

## Connect And Read

```matlab
ports = labkit.mark10.ports();
connection = labkit.mark10.connect(ports(1));
cleanup = onCleanup(@() labkit.mark10.disconnect(connection));

[connection, sample] = labkit.mark10.readSample(connection);
if sample.Valid
    fprintf("%.4g N, %.4g mm\n", sample.Force_N, sample.Travel_mm)
end
```

For a responsive live application, use background sampling rather than
calling `readSample` from a GUI timer:

```matlab
sampler = labkit.mark10.startSampling(connection, 0.02, @consumeSample);
samplingCleanup = onCleanup(@() labkit.mark10.stopSampling(sampler));
```

`connect` starts one persistent background worker that exclusively owns the
physical serial port until `disconnect`. `startSampling` changes that driver's
state from connected-idle to monitoring; the driver assembles and timestamps
each synchronized two-line response, then transfers samples to the client in
batches. GUI rendering and batch delivery therefore do not set the serial
request pace. `setSamplingPeriod` changes the producer rate without replacing
the owner. `stopSampling` flushes the final batch and returns to connected-idle
without closing the port.

The ESM303 `n` response contains force and travel but no device timestamp.
Each sample therefore includes `HostTime_s`, a monotonic timestamp taken by
the background driver when the complete response is accepted. It is not the
later GUI-delivery time.

Connection probes are independent: identity commands may be unavailable while
force/travel acquisition remains usable. `readSample` first requests the
synchronized ESM303 `n` response, quiesces and retries after contamination,
then falls back to ESM303 `x` plus Series 5 `?C`. A failed sample is reported
without discarding the connection or earlier caller-owned records.

## Functions

| Task | Function |
| --- | --- |
| List or probe serial ports | `labkit.mark10.ports`, `labkit.mark10.discover` |
| Connect and disconnect | `labkit.mark10.connect`, `labkit.mark10.disconnect` |
| Read force and travel | `labkit.mark10.readSample` |
| Control background sampling | `labkit.mark10.startSampling`, `labkit.mark10.setSamplingPeriod`, `labkit.mark10.stopSampling` |
| Decode offline responses | `labkit.mark10.decodeSample`, `labkit.mark10.decodeSettings` |
| Read or verify one setting | `labkit.mark10.readSettings`, `labkit.mark10.writeSetting` |
| Zero force or travel | `labkit.mark10.zeroForce`, `labkit.mark10.zeroTravel` |
| Inspect compatibility | `labkit.mark10.version` |

## Settings And Safety

`writeSetting` supports units, measurement mode, current/display filters,
output format, polarity flags, Auto Output, and auto shutoff. Every setter is
checked against a subsequent `LIST` readback. A silent setter can therefore
return `NO_ACK_BUT_READBACK_CONFIRMED`. Nonzero Auto Output is verified, held
at zero during synchronous monitoring, and restored by `disconnect`.

LabKit defines tension as positive and compression as negative. The Series 5
default is the opposite, so the driver applies `IPOL1` and verifies it by
`LIST` at connect and before sampling. It never repairs polarity with `abs` or
an App-only sign flip. `SAVE` is still not sent; reconnecting re-establishes
the convention after a gauge power cycle.

Travel zero uses the stand status command to gate hardware `z` and succeeds
only after the ESM303 reports a zero position within its documented travel
resolution. When the current stand mode does not expose that command path, the
operation fails without creating a software offset. Force zero is likewise a
verified device command. Callers must still confirm that the fixture is in a
mechanically safe state before any zero operation.

## Hardware Configuration

Use 115200 baud, 8 data bits, no parity, and one stop bit for the stand and
gauge link. The driver sends CR-terminated GCL2 commands only while in gauge
pass-through and sends fixed ESM303 commands without adding a terminator.
Do not run another serial console or MESUR session on the same port.
