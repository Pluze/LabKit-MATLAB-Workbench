function [item, status] = loadFile(filepath, expectedKind, opts)
%LOADFILE Load one supported DTA file without GUI side effects.
%
% Usage:
%   [item, status] = labkit.dta.loadFile(filepath);
%   [item, status] = labkit.dta.loadFile(filepath, "chrono");
%
% Inputs:
%   filepath - char/string path to one Gamry DTA file.
%   expectedKind - "auto" (default), "chrono", "eis", or "cvct".
%   opts - optional struct passed to kind-specific item construction.
%
% Options:
%   For chrono files, opts may contain pulse-detection options accepted by
%   labkit.dta.detectPulses through the private chrono item builder.
%
% Output:
%   item - parsed DTA item struct when status.ok is true.
%   status - struct with ok, message, kind, expectedKind, and filepath.

    if nargin < 2
        expectedKind = "auto";
    end
    if nargin < 3
        opts = struct();
    end

    filepath = normalizeFilepath(filepath);
    expectedKind = normalizeExpectedKind(expectedKind);
    item = struct([]);
    status = makeStatus(filepath, "unknown", expectedKind, "");

    if expectedKind == "auto"
        [detectedKind, detectStatus] = labkit.dta.detectType(filepath);
        if ~detectStatus.ok
            status = withExpectedKind(detectStatus, expectedKind);
            return;
        end
        kind = detectedKind;
    else
        [detectedKind, detectStatus] = labkit.dta.detectType(filepath);
        if detectStatus.ok && detectedKind ~= expectedKind
            status.kind = detectedKind;
            status.message = sprintf('Expected %s DTA, detected %s.', expectedKind, detectedKind);
            return;
        elseif ~detectStatus.ok && contains(detectStatus.message, 'File not found')
            status = withExpectedKind(detectStatus, expectedKind);
            return;
        end
        kind = expectedKind;
    end

    try
        item = loadByKind(filepath, kind, opts);

        status.ok = true;
        status.kind = kind;
        status.message = "";
    catch ME
        status = statusForLoadFailure(filepath, kind, expectedKind, ME);
    end
end

function filepath = normalizeFilepath(filepath)
    if ~(ischar(filepath) || (isstring(filepath) && isscalar(filepath)))
        error('labkit:dta:InvalidFilepath', 'Filepath must be a character vector or scalar string.');
    end
    filepath = char(filepath);
end

function status = makeStatus(filepath, kind, expectedKind, message)
    status = struct( ...
        'ok', false, ...
        'message', string(message), ...
        'kind', string(kind), ...
        'expectedKind', string(expectedKind), ...
        'filepath', filepath);
end

function status = withExpectedKind(status, expectedKind)
    status = makeStatus(status.filepath, status.kind, expectedKind, status.message);
end

function status = statusForLoadFailure(filepath, kind, expectedKind, loadError)
    status = makeStatus(filepath, kind, expectedKind, loadError.message);
    if expectedKind == "auto"
        return;
    end

    [detectedKind, detectStatus] = labkit.dta.detectType(filepath);
    if detectStatus.ok && detectedKind ~= expectedKind
        status.kind = detectedKind;
        status.message = sprintf('Expected %s DTA, detected %s.', expectedKind, detectedKind);
    elseif ~detectStatus.ok && contains(detectStatus.message, 'File not found')
        status.kind = detectStatus.kind;
        status.message = detectStatus.message;
    end
end

function item = loadByKind(filepath, kind, opts)
    switch kind
        case "chrono"
            item = makeChronoItem(filepath, opts);
        case "eis"
            item = makeEISItem(filepath);
        case "cvct"
            item = makeCVCTItem(filepath);
        otherwise
            error('labkit:dta:UnsupportedKind', 'Unsupported DTA type: %s.', kind);
    end
end

function item = makeCVCTItem(filepath)
    [scanRate, curves, logmsg] = parseCVCTDTA(filepath);
    if isempty(curves)
        error('No CV/CT curve section was parsed from this DTA file.');
    end

    item = struct();
    item.type = "cvct";
    item.filepath = filepath;
    item.name = shortName(filepath);
    item.scanRate = scanRate;
    item.scanRate_V_per_s = scanRate;
    item.curves = curves;
    item.logmsg = logmsg;
    item.analysis = struct();
end

function name = shortName(filepath)
    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end
