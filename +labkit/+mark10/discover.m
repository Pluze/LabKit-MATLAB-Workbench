function [port, report] = discover(varargin)
%DISCOVER Find the first plausible Mark-10 ESM303 serial port.
%
% Usage:
%   [port,report] = labkit.mark10.discover()
%   [port,report] = labkit.mark10.discover(Ports=ports, Timeout=seconds)
%
% Description:
%   Opens candidate ports at 115200 8-N-1 and accepts a port only when the
%   ESM303 combined or travel response parses. Series 5 identity is an
%   independent capability and does not gate an otherwise useful stand.
%   Each temporary connection is disconnected and its original Auto Output
%   setting is restored before the next candidate is tried.
%
% Inputs:
%   None.
%
% Options:
%   Ports - Text array of candidates. Default: labkit.mark10.ports().
%   Timeout - Positive scalar response timeout in seconds. Default: 0.3.
%
% Outputs:
%   port - First plausible port or empty string.
%   report - Table with Port, Plausible, CombinedStatus, TravelStatus, and
%       Series5Status columns. It contains no device serial number.
%
% Errors:
%   labkit:mark10:InvalidValue - Options are malformed.
%
% Typical Call:
%   [port,report] = labkit.mark10.discover();
%
% See also labkit.mark10.ports, labkit.mark10.connect
    options = parseOptions(varargin{:});
    candidates = options.Ports;
    rows = cell(numel(candidates), 5);
    rowCount = 0;
    port = "";
    for candidate = candidates(:).'
        connection = [];
        plausible = false;
        combined = "NO_RESPONSE";
        travel = "NO_RESPONSE";
        series5 = "UNKNOWN";
        try
            connection = labkit.mark10.connect(candidate, ...
                Timeout=options.Timeout);
            plausible = true;
            combined = connection.Capabilities.CombinedSample;
            travel = connection.Capabilities.TravelSample;
            series5 = connection.Capabilities.GaugeIdentity;
            if strlength(port) == 0
                port = candidate;
            end
        catch
            % Discovery reports an unavailable candidate and continues.
        end
        if ~isempty(connection)
            labkit.mark10.disconnect(connection);
        end
        rowCount = rowCount + 1;
        rows(rowCount, :) = {candidate, plausible, combined, travel, series5};
        if strlength(port) > 0
            break;
        end
    end
    report = cell2table(rows(1:rowCount, :), VariableNames=[ ...
        "Port", "Plausible", "CombinedStatus", "TravelStatus", ...
        "Series5Status"]);
end

function options = parseOptions(varargin)
p = inputParser;
p.FunctionName = "labkit.mark10.discover";
p.addParameter("Ports", labkit.mark10.ports(), @isText);
p.addParameter("Timeout", 0.3, @isPositiveScalar);
p.parse(varargin{:});
options = p.Results;
options.Ports = string(options.Ports(:));
options.Timeout = double(options.Timeout);
end

function accepted = isText(value)
accepted = ischar(value) || isstring(value) || iscellstr(value);
end

function accepted = isPositiveScalar(value)
accepted = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end
