function [kind, status] = detectType(filepath)
%DETECTTYPE Identify the supported Gamry DTA data family in a file.
%
% Usage:
%   [kind, status] = labkit.dta.detectType(filepath)
%
% Description:
%   Reads enough of one DTA file to determine whether it contains EIS,
%   cyclic-voltammetry/charge-time, or chrono data. Detection verifies usable
%   curve columns rather than relying on the filename. A missing or unsupported
%   file is reported in status instead of throwing a read error.
%
% Inputs:
%   filepath - Character vector or string scalar naming one DTA file.
%
% Outputs:
%   kind - String scalar: "chrono", "eis", "cvct", or "unknown".
%   status - Scalar structure describing detection. ok is true only for a
%       recognized file; message is empty on success and explains failure
%       otherwise; kind repeats the detected value; and filepath contains the
%       normalized character-vector path.
%
% Errors:
%   Throws labkit:dta:InvalidFilepath when filepath is not a character vector
%   or string scalar.
%
% Example:
%   [kind, status] = labkit.dta.detectType("experiment.DTA");
%   if status.ok
%       fprintf("Detected %s data.\n", kind)
%   else
%       warning("%s", status.message)
%   end

    filepath = normalizeFilepath(filepath);
    kind = "unknown";
    status = makeStatus(filepath, kind, "");

    if exist(filepath, 'file') ~= 2
        status.message = sprintf('File not found: %s', filepath);
        return;
    end

    probes = {@isEIS, @isCVCT, @isChrono};
    kinds = ["eis", "cvct", "chrono"];
    messages = strings(size(kinds));

    for k = 1:numel(probes)
        [ok, msg] = probes{k}(filepath);
        if ok
            kind = kinds(k);
            status.ok = true;
            status.kind = kind;
            status.message = "";
            return;
        end
        messages(k) = msg;
    end

    status.message = sprintf('Could not detect supported DTA type: %s', strjoin(cellstr(messages), ' | '));
end

function filepath = normalizeFilepath(filepath)
    if ~(ischar(filepath) || (isstring(filepath) && isscalar(filepath)))
        error('labkit:dta:InvalidFilepath', 'Filepath must be a character vector or scalar string.');
    end
    filepath = char(filepath);
end

function status = makeStatus(filepath, kind, message)
    status = struct( ...
        'ok', false, ...
        'message', string(message), ...
        'kind', string(kind), ...
        'filepath', filepath);
end

function [ok, msg] = isEIS(filepath)
    ok = false;
    msg = "";
    try
        [~, tables] = parseEISDTA(filepath);
        [~, ok, msg] = labkit.dta.getZCurve(tables);
    catch ME
        msg = string(ME.message);
    end
end

function [ok, msg] = isChrono(filepath)
    ok = false;
    msg = "";
    try
        [~, tables] = parseChronoDTA(filepath);
        [curve, tableOk, msg] = labkit.dta.getMainCurve(tables);
        if ~tableOk
            return;
        end

        t = labkit.dta.getColumn(curve, 'T');
        vf = labkit.dta.getColumn(curve, 'Vf');
        im = labkit.dta.getColumn(curve, 'Im');
        valid = isfinite(t) & isfinite(vf) & isfinite(im);
        ok = sum(valid) >= 2;
        if ~ok
            msg = "Not enough valid T/Vf/Im points.";
        end
    catch ME
        msg = string(ME.message);
    end
end

function [ok, msg] = isCVCT(filepath)
    ok = false;
    msg = "";
    try
        [scanRate, curves, logmsg] = parseCVCTDTA(filepath);
        ok = ~isempty(curves) && isfinite(scanRate);
        if ok
            msg = "Detected CV/CT curve section.";
        elseif ~isfinite(scanRate)
            msg = "No CV/CT scan rate found.";
        elseif ~isempty(logmsg)
            msg = string(logmsg{end});
        else
            msg = "No CV/CT curve section found.";
        end
    catch ME
        msg = string(ME.message);
    end
end
