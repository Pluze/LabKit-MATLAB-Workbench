function [connection, sample] = readSample(connection)
%READSAMPLE Acquire one normalized force/travel sample with fallback.
%
% Usage:
%   [connection,sample] = labkit.mark10.readSample(connection)
%
% Description:
%   Requests synchronized force and travel with ESM303 n. A malformed or
%   missing response triggers one AOUT quiesce/resynchronization and retry,
%   then falls back to ESM303 x plus Series 5 ?C. Temporary failure returns
%   Valid=false and increments the connection sample counter; it does not
%   disconnect or discard earlier App-owned records.
%
% Inputs:
%   connection - Opaque token returned by labkit.mark10.connect.
%
% Outputs:
%   connection - Updated token with SampleCount, AcquisitionMode, and
%       LastFailure.
%   sample - Scalar struct with SampleIndex, Force_N, Travel_mm, raw
%       value/unit fields, Valid, AcquisitionMode, ResponseTime_s, RawText,
%       and FailureStatus.
%
% Errors:
%   labkit:mark10:InvalidConnection - connection is malformed.
%
% Typical Call:
%   [connection,sample] = labkit.mark10.readSample(connection);
%
% See also labkit.mark10.decodeSample, labkit.mark10.connect
    connection = requireMark10Connection(connection);
    connection.SampleCount = connection.SampleCount + uint64(1);
    [raw, outcome, elapsed] = mark10StandRequest( ...
        connection, "n", 2, false);
    sample = labkit.mark10.decodeSample(raw);
    if ~sample.Valid
        connection = resynchronize(connection);
        [raw, outcome, elapsed] = mark10StandRequest( ...
            connection, "n", 2, true);
        sample = labkit.mark10.decodeSample(raw);
    end
    if ~sample.Valid
        sample = fallbackSample(connection);
        elapsed = sample.ResponseTime_s;
        outcome = sample.FailureStatus;
    end
    sample.SampleIndex = connection.SampleCount;
    sample.ResponseTime_s = elapsed;
    if sample.Valid
        connection.AcquisitionMode = sample.AcquisitionMode;
        connection.LastFailure = struct("Status", "", "Message", "");
    else
        if strlength(outcome) == 0
            outcome = "UNSUPPORTED";
        end
        sample.FailureStatus = outcome;
        connection.LastFailure = struct("Status", outcome, ...
            "Message", "No valid force/travel sample was received.");
    end
end

function connection = resynchronize(connection)
t = connection.Transport;
try
    t.Flush();
    t.Write(uint8('/'));
    t.Pause(0.015);
    t.Write([uint8('AOUT0'), uint8(13)]);
    t.ReadFor(0.1);
    t.Write(uint8('\'));
    t.Pause(0.01);
    t.Flush();
catch
    try
        t.Write(uint8('\'));
        t.Flush();
    catch
    end
end
end

function sample = fallbackSample(connection)
started = tic;
[rawTravel, travelOutcome] = mark10StandRequest( ...
    connection, "x", 1, true);
travel = mark10TravelReading(rawTravel);
[rawForce, forceOutcome] = mark10GaugeRequest(connection, "?C");
force = mark10ForceReading(rawForce);
sample = struct( ...
    "Force_N", force.Force_N, "Travel_mm", travel.Travel_mm, ...
    "ForceRawValue", force.Value, "ForceUnit", force.Unit, ...
    "TravelRawValue", travel.Value, "TravelUnit", travel.Unit, ...
    "Valid", force.Valid && travel.Valid, ...
    "AcquisitionMode", "Fallback x + ?C", ...
    "RawText", force.RawText + newline + travel.RawText, ...
    "FailureStatus", fallbackOutcome(forceOutcome, travelOutcome), ...
    "ResponseTime_s", toc(started));
end

function outcome = fallbackOutcome(forceOutcome, travelOutcome)
if forceOutcome == "ERROR_RESPONSE" || travelOutcome == "ERROR_RESPONSE"
    outcome = "ERROR_RESPONSE";
elseif forceOutcome == "NO_RESPONSE" || travelOutcome == "NO_RESPONSE"
    outcome = "NO_RESPONSE";
else
    outcome = "UNSUPPORTED";
end
end
