function [connection, result] = zeroForce(connection)
%ZEROFORCE Zero the Series 5 current reading and verify its resolution.
%
% Usage:
%   [connection,result] = labkit.mark10.zeroForce(connection)
%
% Description:
%   Reads ?C, sends the documented Series 5 Z command through isolated
%   pass-through, and reads ?C again. Verification accepts a residual no
%   larger than two least-significant displayed increments derived from the
%   returned value and unit; it does not invent a model-independent force
%   tolerance.
%
% Inputs:
%   connection - Opaque token returned by labkit.mark10.connect.
%
% Outputs:
%   connection - Updated token with LastFailure.
%   result - Scalar struct with Success, Status, Before_N, After_N, and
%       Resolution_N.
%
% Errors:
%   labkit:mark10:InvalidConnection - connection is malformed.
%
% Typical Call:
%   [connection,result] = labkit.mark10.zeroForce(connection);
%
% See also labkit.mark10.zeroTravel
    connection = requireMark10Connection(connection);
    [beforeRaw, ~] = mark10GaugeRequest(connection, "?C");
    before = mark10ForceReading(beforeRaw);
    [~, commandOutcome] = mark10GaugeCommand(connection, "Z");
    [afterRaw, afterOutcome] = mark10GaugeRequest(connection, "?C");
    after = mark10ForceReading(afterRaw);
    success = after.Valid && isfinite(after.Resolution_N) && ...
        abs(after.Force_N) <= 2 * after.Resolution_N;
    status = zeroStatus(success, commandOutcome, afterOutcome);
    result = struct("Success", success, "Status", status, ...
        "Before_N", before.Force_N, "After_N", after.Force_N, ...
        "Resolution_N", after.Resolution_N, "Message", "");
    if ~success
        result.Message = "Force zero could not be confirmed by ?C readback.";
        connection.LastFailure = struct("Status", status, ...
            "Message", result.Message);
    end
end

function status = zeroStatus(success, commandOutcome, readOutcome)
if success && commandOutcome == "NO_RESPONSE"
    status = "NO_ACK_BUT_READBACK_CONFIRMED";
elseif success
    status = "SUPPORTED";
elseif commandOutcome == "ERROR_RESPONSE" || readOutcome == "ERROR_RESPONSE"
    status = "ERROR_RESPONSE";
elseif commandOutcome == "NO_RESPONSE" && readOutcome == "NO_RESPONSE"
    status = "NO_RESPONSE";
else
    status = "UNSUPPORTED";
end
end
