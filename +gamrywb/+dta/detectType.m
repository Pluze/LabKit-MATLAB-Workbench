function [kind, status] = detectType(filepath)
%DETECTTYPE Detect the supported Gamry DTA family for one file.

    filepath = normalizeFilepath(filepath);
    kind = "unknown";
    status = makeStatus(filepath, kind, "");

    if exist(filepath, 'file') ~= 2
        status.message = sprintf('File not found: %s', filepath);
        return;
    end

    probes = {@isEIS, @isChrono, @isCVCT};
    kinds = ["eis", "chrono", "cvct"];
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
        error('gamrywb:dta:InvalidFilepath', 'Filepath must be a character vector or scalar string.');
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
        [~, ok, msg] = gamrywb.dta.getZCurve(tables);
    catch ME
        msg = string(ME.message);
    end
end

function [ok, msg] = isChrono(filepath)
    ok = false;
    msg = "";
    try
        [~, tables] = parseChronoDTA(filepath);
        [curve, tableOk, msg] = gamrywb.dta.getMainCurve(tables);
        if ~tableOk
            return;
        end

        t = gamrywb.dta.getColumn(curve, 'T');
        vf = gamrywb.dta.getColumn(curve, 'Vf');
        im = gamrywb.dta.getColumn(curve, 'Im');
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
        [~, curves, logmsg] = parseCVCTDTA(filepath);
        ok = ~isempty(curves);
        if ok
            msg = "Detected CV/CT curve section.";
        elseif ~isempty(logmsg)
            msg = string(logmsg{end});
        else
            msg = "No CV/CT curve section found.";
        end
    catch ME
        msg = string(ME.message);
    end
end
