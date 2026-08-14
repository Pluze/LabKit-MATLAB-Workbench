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

Travel zero uses the stand status command to gate hardware `z`. When the
current stand mode does not expose that command path but travel is readable,
the result supplies a software offset. Force zero is verified against the
displayed gauge resolution. Callers must still confirm that the fixture is in
a mechanically safe state before any zero operation.

## Hardware Configuration

Use 115200 baud, 8 data bits, no parity, and one stop bit for the stand and
gauge link. The driver sends CR-terminated GCL2 commands only while in gauge
pass-through and sends fixed ESM303 commands without adding a terminator.
Do not run another serial console or MESUR session on the same port.
