function [connection, settings, result] = writeSetting( ...
        connection, name, value)
%WRITESETTING Apply one safe Series 5 setting with readback verification.
%
% Usage:
%   [connection,settings,result] = ...
%       labkit.mark10.writeSetting(connection,name,value)
%
% Description:
%   Reads a baseline LIST, sends one documented non-motion GCL2 setter, then
%   reads LIST again and verifies the requested field. A silent setter with a
%   matching readback returns NO_ACK_BUT_READBACK_CONFIRMED. SAVE is never
%   sent automatically. Nonzero Auto Output is verified from a mixed LIST /
%   unsolicited stream, then held at AOUT0 for synchronous force/travel
%   monitoring and restored on disconnect.
%
% Inputs:
%   connection - Opaque token returned by labkit.mark10.connect.
%   name - "unit", "mode", "currentFilter", "displayFilter",
%       "outputFormat", "invertPolarity", "omitPolarity", "autoOutput",
%       or "autoShutoff".
%   value - Legal value for the named setting. Units: "N", "mN", "kN",
%       "lbF", "ozF", "kgF", or "gF". Modes: "CUR", "PT", or "PC".
%       Filters: powers of two from 1 through 1024. Output formats: "FULL"
%       or "NUM". Polarity values: logical scalar. Auto Output: 0, 1, 2,
%       5, 10, 25, 50, 125, or 250 Hz. Auto Shutoff: integer 0 through 30 min.
%
% Outputs:
%   connection - Updated token, including requested Auto Output restoration.
%   settings - Verified current settings snapshot. ActiveAutoOutput remains
%       zero when a nonzero setting is staged for disconnect restoration.
%   result - Scalar struct with Success, Status, Command, Baseline, and
%       Message fields.
%
% Errors:
%   labkit:mark10:InvalidValue - Name or value is unsupported.
%   labkit:mark10:InvalidConnection - connection is malformed.
%
% Typical Call:
%   [connection,settings,result] = ...
%       labkit.mark10.writeSetting(connection,"unit","N");
%
% See also labkit.mark10.readSettings, labkit.mark10.disconnect
    connection = requireMark10Connection(connection);
    if mark10IsServiceConnection(connection)
        request = struct("Name", string(name), "Value", value);
        [connection, payload] = mark10ServiceRequest( ...
            connection, "writeSetting", request);
        settings = payload{1};
        result = payload{2};
        return;
    end
    [connection, baseline] = labkit.mark10.readSettings(connection);
    [command, expected] = settingCommand(name, value);
    if lower(string(name)) == "autooutput" && expected > 0
        [connection, settings, verified, response] = ...
            stageAutoOutput(connection, expected);
    else
        [response, responseOutcome] = mark10GaugeCommand(connection, command);
        [connection, settings] = labkit.mark10.readSettings(connection);
        verified = settingMatches(settings, name, expected);
        response = struct("Raw", mark10ResponseText(response), ...
            "Outcome", responseOutcome);
    end
    success = verified;
    if success && response.Outcome == "NO_RESPONSE"
        status = "NO_ACK_BUT_READBACK_CONFIRMED";
    elseif success
        status = "SUPPORTED";
    elseif response.Outcome == "ERROR_RESPONSE"
        status = "ERROR_RESPONSE";
    elseif response.Outcome == "NO_RESPONSE"
        status = "NO_RESPONSE";
    else
        status = "UNSUPPORTED";
    end
    result = struct("Success", success, "Status", status, ...
        "Command", command, "Baseline", baseline, ...
        "Message", resultMessage(success, status));
    if ~success
        connection.LastFailure = struct("Status", status, ...
            "Message", result.Message);
    end
end

function [command, expected] = settingCommand(name, value)
name = lower(scalarText(name, "setting name"));
switch name
    case "unit"
        [command, expected] = unitCommand(value);
    case "mode"
        expected = upper(scalarText(value, "mode"));
        requireChoice(expected, ["CUR", "PT", "PC"], "mode");
        command = expected;
    case {"currentfilter", "displayfilter"}
        expected = filterValue(value);
        exponent = round(log2(expected));
        prefix = ternary(name == "currentfilter", "FLTC", "FLTP");
        command = prefix + exponent;
    case "outputformat"
        expected = upper(scalarText(value, "output format"));
        requireChoice(expected, ["FULL", "NUM"], "output format");
        command = expected;
    case {"invertpolarity", "omitpolarity"}
        if ~(islogical(value) && isscalar(value))
            invalid("polarity value must be logical scalar");
        end
        expected = value;
        prefix = ternary(name == "invertpolarity", "IPOL", "OPOL");
        command = prefix + double(value);
    case "autooutput"
        expected = numericChoice(value, [0, 1, 2, 5, 10, 25, 50, 125, 250], ...
            "Auto Output rate");
        command = "AOUT" + expected;
    case "autoshutoff"
        if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
                value == fix(value) && value >= 0 && value <= 30)
            invalid("Auto Shutoff must be an integer from 0 through 30");
        end
        expected = double(value);
        command = "AOFF" + expected;
    otherwise
        invalid("setting name is unsupported");
end
end

function [command, expected] = unitCommand(value)
value = upper(scalarText(value, "unit"));
units = ["N", "MN", "KN", "LBF", "OZF", "KGF", "GF"];
commands = ["N", "MN", "KN", "LB", "OZ", "KG", "G"];
match = find(units == value, 1);
if isempty(match)
    invalid("unit is unsupported");
end
command = commands(match);
expected = units(match);
end

function value = filterValue(value)
allowed = 2 .^ (0:10);
value = numericChoice(value, allowed, "filter");
end

function value = numericChoice(value, allowed, label)
if ~(isnumeric(value) && isscalar(value) && isfinite(value) && any(value == allowed))
    invalid(label + " is unsupported");
end
value = double(value);
end

function [connection, settings, verified, response] = ...
        stageAutoOutput(connection, rate)
t = connection.Transport;
t.Flush();
t.Write(uint8('/'));
t.Pause(0.015);
t.Write([uint8(char("AOUT" + rate)), uint8(13)]);
stream = t.ReadFor(0.12);
t.Write([uint8('LIST'), uint8(13)]);
mixed = [stream; t.ReadFor(max(0.3, connection.Timeout))];
staged = labkit.mark10.decodeSettings(mixed);
verified = staged.AutoOutput == rate;
t.Write([uint8('AOUT0'), uint8(13)]);
t.Pause(0.1);
t.ReadFor(0.1);
t.Write(uint8('\'));
t.Pause(0.01);
t.Flush();
[connection, settings] = labkit.mark10.readSettings(connection);
settings.AutoOutput = rate;
settings.ActiveAutoOutput = 0;
connection.Settings = settings;
if verified
    connection.RestoreAutoOutput = "AOUT" + rate;
end
response = struct("Raw", mark10ResponseText(stream), ...
    "Outcome", ternary(isempty(stream), "NO_RESPONSE", "RESPONSE"));
end

function matched = settingMatches(settings, name, expected)
switch lower(string(name))
    case "unit"
        actual = settings.Unit;
    case "mode"
        actual = settings.Mode;
    case "currentfilter"
        actual = settings.CurrentFilter;
    case "displayfilter"
        actual = settings.DisplayFilter;
    case "outputformat"
        actual = settings.OutputFormat;
    case "invertpolarity"
        actual = settings.InvertPolarity;
    case "omitpolarity"
        actual = settings.OmitPolarity;
    case "autooutput"
        actual = settings.AutoOutput;
    case "autoshutoff"
        actual = settings.AutoShutoff;
end
matched = isequal(actual, expected);
end

function value = scalarText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(strip(string(value))) == 0
    invalid(label + " must be nonempty scalar text");
end
value = string(value);
end

function requireChoice(value, choices, label)
if ~any(value == choices)
    invalid(label + " is unsupported");
end
end

function message = resultMessage(success, status)
if success
    message = "Setting readback matched the requested value.";
else
    message = "Setting could not be confirmed by Series 5 readback (" + ...
        status + ").";
end
end

function invalid(message)
error("labkit:mark10:InvalidValue", "Mark-10 %s.", message);
end

function value = ternary(condition, whenTrue, whenFalse)
if condition
    value = whenTrue;
else
    value = whenFalse;
end
end
