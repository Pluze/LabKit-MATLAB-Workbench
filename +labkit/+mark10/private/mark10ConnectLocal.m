function connection = mark10ConnectLocal(port, varargin)
%MARK10CONNECTLOCAL Open and probe the physical serial port.
%
% Usage:
%   connection = labkit.mark10.connect(port)
%   connection = labkit.mark10.connect(port, Timeout=seconds)
%
% Description:
%   Opens one serial port at the official ESM303 115200 8-N-1 data-output
%   settings, separates unsolicited Series 5 Auto Output from command mode,
%   and probes combined force/travel, travel, gauge identity, settings, and
%   mode-dependent stand status independently. The returned connection is an
%   opaque scalar token for the other labkit.mark10 functions. Auto Output is
%   held at zero while synchronous monitoring is active and restored by
%   disconnect.
%
% Inputs:
%   port - Nonempty scalar serial port name.
%
% Options:
%   Timeout - Positive scalar response timeout in seconds. Default: 0.3.
%
% Outputs:
%   connection - Opaque scalar driver token. Public fields Identity,
%       Capabilities, Settings, Port, and RestoreAutoOutput are diagnostic
%       snapshots; callers must not modify the token.
%
% Errors:
%   labkit:mark10:InvalidValue - Port or Timeout is malformed.
%   labkit:mark10:ConnectionFailed - The port cannot be opened or neither an
%       ESM303 combined nor travel response can be parsed.
%
% Typical Call:
%   connection = labkit.mark10.connect("COM4");
%   cleanup = onCleanup(@() labkit.mark10.disconnect(connection));
%
% See also labkit.mark10.disconnect, labkit.mark10.readSample,
%   labkit.mark10.readSettings
    port = scalarText(port, "port");
    p = inputParser;
    p.FunctionName = "labkit.mark10.connect";
    p.addParameter("Timeout", 0.3, @isPositiveScalar);
    p.parse(varargin{:});
    timeout = double(p.Results.Timeout);
    transport = [];
    try
        transport = serialTransport(port, timeout);
        connection = connectionToken(port, timeout, transport);
        [connection, preflightSettings] = quiesceAutoOutput(connection);

        [rawCombined, ~] = standRequest(connection, "n", 2, false);
        combined = labkit.mark10.decodeSample(rawCombined);
        if ~combined.Valid
            % A saved high-rate Auto Output setting can leave complete force
            % lines in the OS receive buffer while the port is opening.
            % Repeat the quiesce boundary before declaring synchronized n
            % unsupported; capability probing must never classify that
            % unsolicited tail as the command response.
            [connection, retrySettings] = quiesceAutoOutput(connection);
            if strlength(preflightSettings.Raw) == 0 && ...
                    strlength(retrySettings.Raw) > 0
                preflightSettings = retrySettings;
            end
            [rawCombined, ~] = standRequest(connection, "n", 2, true);
            combined = labkit.mark10.decodeSample(rawCombined);
        end
        [rawTravel, ~] = standRequest(connection, "x", 1, true);
        [travelValue, travelUnit] = parseTravel(rawTravel);
        travelSupported = isfinite(travelValue) && strlength(travelUnit) > 0;
        if ~combined.Valid && ~travelSupported
            error("labkit:mark10:ConnectionFailed", ...
                "The selected port did not return a plausible ESM303 response.");
        end

        identity = readIdentity(connection);
        settings = preflightSettings;
        if strlength(settings.Raw) == 0
            [connection, settings] = labkit.mark10.readSettings(connection);
        end
        connection.Settings = settings;
        connection = mark10EnsureForceConvention(connection);
        settings = connection.Settings;
        if settings.AutoOutput > 0
            connection.RestoreAutoOutput = "AOUT" + settings.AutoOutput;
            [connection, ~] = disableAutoOutput(connection);
            settings.ActiveAutoOutput = 0;
        end
        [rawStatus, statusOutcome] = standRequest(connection, "p", 1, true);
        standStatus = upper(strip(decodeText(rawStatus)));
        statusSupported = statusOutcome == "RESPONSE" && ...
            any(standStatus == ["U", "D", "S", "C", "L", "M", "UL", "DL"]);

        capabilities = struct( ...
            "CombinedSample", capability(combined.Valid, rawCombined), ...
            "TravelSample", capability(travelSupported, rawTravel), ...
            "GaugeIdentity", identity.Status, ...
            "GaugeSettings", capability(strlength(settings.Raw) > 0, ...
                uint8(char(settings.Raw))), ...
            "ForcePolarity", "TENSION_POSITIVE_COMPRESSION_NEGATIVE", ...
            "HardwareTravelZero", ternary(statusSupported, "SUPPORTED", ...
                "CURRENT_MODE_UNAVAILABLE"), ...
            "GaugeZero", ternary(identity.Status == "SUPPORTED", ...
                "SUPPORTED", "UNKNOWN"));
        connection.Identity = identity;
        connection.Settings = settings;
        connection.Capabilities = capabilities;
        connection.AcquisitionMode = ternary(combined.Valid, ...
            "Synchronized n", "Fallback x + ?C");
        connection.LastFailure = struct("Status", "", "Message", "");
    catch cause
        if ~isempty(transport)
            try
                transport.Close();
            catch
            end
        end
        if startsWith(string(cause.identifier), "labkit:mark10:")
            rethrow(cause);
        end
        failure = MException("labkit:mark10:ConnectionFailed", ...
            "Could not open or probe Mark-10 port %s.", port);
        failure = addCause(failure, cause);
        throwAsCaller(failure);
    end
end

function transport = serialTransport(port, timeout)
sp = serialport(char(port), 115200, Timeout=timeout);
sp.DataBits = 8;
sp.StopBits = 1;
sp.Parity = "none";
sp.FlowControl = "none";
configureTerminator(sp, "LF");
transport = struct( ...
    "Write", @(bytes) write(sp, uint8(bytes), "uint8"), ...
    "Flush", @() flush(sp, "input"), ...
    "ReadUntil", @(lineCount, seconds) readUntil(sp, lineCount, seconds), ...
    "ReadFor", @(seconds) readFor(sp, seconds), ...
    "ConfigureLineCallback", @(callback) ...
        configureCallback(sp, "terminator", callback), ...
    "DisableCallback", @() configureCallback(sp, "off"), ...
    "ReadAvailable", @() readAvailable(sp), ...
    "Pause", @(seconds) pause(seconds), ...
    "Close", @() closeSerial(sp), ...
    "IsOpen", @() isvalid(sp));
end

function raw = readAvailable(sp)
count = sp.NumBytesAvailable;
if count == 0
    raw = zeros(0, 1, "uint8");
else
    raw = uint8(read(sp, count, "uint8"));
    raw = raw(:);
end
end

function raw = readUntil(sp, lineCount, timeout)
maximumResponseBytes = 65536;
raw = zeros(maximumResponseBytes, 1, "uint8");
used = 0;
started = tic;
while toc(started) < timeout
    count = min(sp.NumBytesAvailable, maximumResponseBytes - used);
    if count > 0
        chunk = uint8(read(sp, count, "uint8"));
        raw(used + (1:count)) = chunk(:);
        used = used + count;
        if sum(raw(1:used) == 10) >= lineCount || ...
                used == maximumResponseBytes
            break;
        end
    else
        pause(0.001);
    end
end
raw = raw(1:used);
end

function raw = readFor(sp, duration)
maximumResponseBytes = 65536;
raw = zeros(maximumResponseBytes, 1, "uint8");
used = 0;
started = tic;
while toc(started) < duration
    count = min(sp.NumBytesAvailable, maximumResponseBytes - used);
    if count > 0
        chunk = uint8(read(sp, count, "uint8"));
        raw(used + (1:count)) = chunk(:);
        used = used + count;
        if used == maximumResponseBytes, break; end
    else
        pause(0.001);
    end
end
raw = raw(1:used);
end

function closeSerial(sp)
if isvalid(sp)
    flush(sp);
    delete(sp);
end
end

function token = connectionToken(port, timeout, transport)
token = struct( ...
    "Type", "labkit.mark10.connection", ...
    "Port", port, ...
    "Timeout", timeout, ...
    "Transport", transport, ...
    "Identity", emptyIdentity(), ...
    "Capabilities", struct(), ...
    "Settings", emptySettings(), ...
    "RestoreAutoOutput", "AOUT0", ...
    "AcquisitionMode", "Unknown", ...
    "SampleCount", uint64(0), ...
    "LastFailure", struct("Status", "", "Message", ""));
end

function [connection, settings] = quiesceAutoOutput(connection)
t = connection.Transport;
t.Flush();
t.ReadFor(min(0.15, connection.Timeout));
% Always cross the gauge pass-through boundary. A quiet initial read does
% not prove Auto Output is disabled: the serial driver or USB adapter may
% not have delivered the saved stream yet.
t.Write(uint8('/'));
t.Pause(0.02);
t.Flush();
t.Write([uint8('LIST'), uint8(13)]);
mixed = t.ReadFor(max(0.3, connection.Timeout));
settings = labkit.mark10.decodeSettings(mixed);
if settings.AutoOutput > 0
    connection.RestoreAutoOutput = "AOUT" + settings.AutoOutput;
end
t.Write([uint8('AOUT0'), uint8(13)]);
t.Pause(0.1);
t.ReadFor(0.1);
t.Write(uint8('\'));
t.Pause(0.02);
t.Flush();
settings.ActiveAutoOutput = 0;
end

function [connection, settings] = disableAutoOutput(connection)
[~, ~] = gaugeCommand(connection, "AOUT0");
[connection, settings] = labkit.mark10.readSettings(connection);
end

function identity = readIdentity(connection)
names = ["RN", "RM", "RV", "RS"];
values = strings(1, 4);
statuses = strings(1, 4);
for index = 1:4
    [raw, statuses(index)] = gaugeRequest(connection, names(index));
    values(index) = strip(decodeText(raw));
end
if all(statuses == "RESPONSE")
    status = "SUPPORTED";
elseif all(statuses == "NO_RESPONSE")
    status = "NO_RESPONSE";
else
    status = "UNKNOWN";
end
identity = struct("Product", values(1), "Model", values(2), ...
    "Firmware", values(3), "Serial", values(4), "Status", status);
end

function value = emptyIdentity()
value = struct("Product", "", "Model", "", "Firmware", "", ...
    "Serial", "", "Status", "UNKNOWN");
end

function value = emptySettings()
value = labkit.mark10.decodeSettings("");
end

function [raw, outcome, elapsed] = standRequest(connection, command, lines, flushFirst)
if flushFirst
    connection.Transport.Flush();
end
started = tic;
connection.Transport.Write(uint8(char(command)));
raw = connection.Transport.ReadUntil(lines, connection.Timeout);
elapsed = toc(started);
outcome = responseOutcome(raw);
end

function [raw, outcome] = gaugeRequest(connection, command)
t = connection.Transport;
t.Flush();
t.Write(uint8('/'));
t.Pause(0.015);
t.Flush();
t.Write([uint8(char(command)), uint8(13)]);
raw = t.ReadUntil(1, connection.Timeout);
t.Write(uint8('\'));
t.Pause(0.01);
t.Flush();
outcome = responseOutcome(raw);
end

function [raw, outcome] = gaugeCommand(connection, command)
t = connection.Transport;
t.Flush();
t.Write(uint8('/'));
t.Pause(0.015);
t.Flush();
t.Write([uint8(char(command)), uint8(13)]);
raw = t.ReadFor(min(0.08, connection.Timeout));
t.Write(uint8('\'));
t.Pause(0.01);
t.Flush();
outcome = responseOutcome(raw);
end

function status = capability(valid, raw)
if valid
    status = "SUPPORTED";
elseif isempty(raw)
    status = "NO_RESPONSE";
elseif startsWith(strip(decodeText(raw)), "*")
    status = "ERROR_RESPONSE";
else
    status = "UNSUPPORTED";
end
end

function outcome = responseOutcome(raw)
if isempty(raw)
    outcome = "NO_RESPONSE";
elseif startsWith(strip(decodeText(raw)), "*")
    outcome = "ERROR_RESPONSE";
else
    outcome = "RESPONSE";
end
end

function value = decodeText(raw)
if isempty(raw)
    value = "";
elseif isstring(raw) || ischar(raw)
    value = string(raw);
else
    value = string(native2unicode(uint8(raw(:).'), "UTF-8"));
end
end

function [value, unit] = parseTravel(raw)
text = decodeText(raw);
token = regexp(char(text), ...
    '([-+]?\d+(?:\.\d+)?)\s*(mm|in)', 'tokens', 'once', 'ignorecase');
if isempty(token)
    value = NaN;
    unit = "";
else
    value = str2double(token{1});
    unit = string(token{2});
end
end

function value = scalarText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(strip(string(value))) == 0
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 %s must be nonempty scalar text.", label);
end
value = string(value);
end

function accepted = isPositiveScalar(value)
accepted = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end

function value = ternary(condition, whenTrue, whenFalse)
if condition
    value = whenTrue;
else
    value = whenFalse;
end
end
