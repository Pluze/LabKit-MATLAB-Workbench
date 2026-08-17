function [connection, settings] = readSettings(connection)
%READSETTINGS Read the current Series 5 identity-independent settings.
%
% Usage:
%   [connection,settings] = labkit.mark10.readSettings(connection)
%
% Description:
%   Requests LIST through an isolated ESM303 pass-through transaction and
%   decodes known settings while retaining unknown tokens. A no-response or
%   error response is reported in connection.LastFailure and does not imply
%   that combined ESM303 monitoring is unavailable.
%
% Inputs:
%   connection - Opaque token returned by labkit.mark10.connect.
%
% Outputs:
%   connection - Updated token with Settings and LastFailure snapshots.
%   settings - Value returned by labkit.mark10.decodeSettings.
%
% Errors:
%   labkit:mark10:InvalidConnection - connection is malformed.
%
% Typical Call:
%   [connection,settings] = labkit.mark10.readSettings(connection);
%
% See also labkit.mark10.writeSetting, labkit.mark10.decodeSettings
    connection = requireMark10Connection(connection);
    if mark10IsServiceConnection(connection)
        [connection, payload] = mark10ServiceRequest( ...
            connection, "readSettings", struct());
        settings = payload{1};
        return;
    end
    [raw, outcome] = mark10GaugeRequest(connection, "LIST");
    settings = labkit.mark10.decodeSettings(raw);
    if strlength(settings.Raw) > 0
        connection.Settings = settings;
        connection.LastFailure = struct("Status", "", "Message", "");
    else
        connection.LastFailure = struct("Status", outcome, ...
            "Message", "Series 5 LIST was unavailable.");
    end
end
