function [connection, result] = zeroTravel(connection)
%ZEROTRAVEL Zero ESM303 travel or return a software-zero offset.
%
% Usage:
%   [connection,result] = labkit.mark10.zeroTravel(connection)
%
% Description:
%   Reads current travel and requests stand status. Hardware z is sent only
%   when status proves the command-capable PC-control path. Otherwise the
%   current travel is returned as SoftwareOffset_mm and the operation succeeds
%   as SUPPORTED_BUT_CURRENT_MODE_UNAVAILABLE. Hardware verification uses the
%   official ESM303 0.02 mm travel resolution and accepts two increments.
%
% Inputs:
%   connection - Opaque token returned by labkit.mark10.connect.
%
% Outputs:
%   connection - Updated token with LastFailure.
%   result - Scalar struct with Success, Status, HardwareApplied,
%       SoftwareOffset_mm, and After_mm.
%
% Errors:
%   labkit:mark10:InvalidConnection - connection is malformed.
%
% Typical Call:
%   [connection,result] = labkit.mark10.zeroTravel(connection);
%
% See also labkit.mark10.zeroForce
    connection = requireMark10Connection(connection);
    [beforeRaw, beforeOutcome] = mark10StandRequest(connection, "x", 1, true);
    before = mark10TravelReading(beforeRaw);
    [statusRaw, statusOutcome] = mark10StandRequest(connection, "p", 1, true);
    standStatus = upper(strip(mark10ResponseText(statusRaw)));
    pcControlAvailable = statusOutcome == "RESPONSE" && ...
        any(standStatus == ["U", "D", "S", "C", "L", "M", "UL", "DL"]);
    if before.Valid && ~pcControlAvailable
        result = struct("Success", true, ...
            "Status", "SUPPORTED_BUT_CURRENT_MODE_UNAVAILABLE", ...
            "HardwareApplied", false, ...
            "SoftwareOffset_mm", before.Travel_mm, ...
            "After_mm", before.Travel_mm, ...
            "Message", "Using the current travel as a software-zero offset.");
        return;
    end
    if ~before.Valid
        result = failure(beforeOutcome, "Travel was unavailable before zero.");
        connection.LastFailure = struct("Status", result.Status, ...
            "Message", result.Message);
        return;
    end
    connection.Transport.Flush();
    connection.Transport.Write(uint8('z'));
    connection.Transport.Pause(0.05);
    [afterRaw, afterOutcome] = mark10StandRequest(connection, "x", 1, true);
    after = mark10TravelReading(afterRaw);
    success = after.Valid && abs(after.Travel_mm) <= 0.04;
    if success
        status = "SUPPORTED";
    else
        status = afterOutcome;
    end
    result = struct("Success", success, "Status", status, ...
        "HardwareApplied", success, "SoftwareOffset_mm", 0, ...
        "After_mm", after.Travel_mm, "Message", "");
    if ~success
        result.Message = "Hardware travel zero could not be confirmed.";
        connection.LastFailure = struct("Status", status, ...
            "Message", result.Message);
    end
end

function result = failure(status, message)
result = struct("Success", false, "Status", status, ...
    "HardwareApplied", false, "SoftwareOffset_mm", NaN, ...
    "After_mm", NaN, "Message", message);
end
