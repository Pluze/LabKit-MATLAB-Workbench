function [item, status] = loadFile(filepath, expectedKind, opts)
%LOADFILE Read one supported Gamry DTA file.
%
% Usage:
%   [item, status] = labkit.dta.loadFile(filepath)
%   [item, status] = labkit.dta.loadFile(filepath, expectedKind)
%   [item, status] = labkit.dta.loadFile(filepath, expectedKind, opts)
%
% Description:
%   Detects and parses one chrono, EIS, or CV/CT DTA file. Set expectedKind to
%   a specific family when a workflow must reject other DTA types. Parse and
%   format failures are returned in status; invalid arguments throw errors.
%
% Inputs:
%   filepath - Character vector or string scalar naming one DTA file.
%   expectedKind - Character vector or string scalar. Allowed values are
%       "auto", "chrono", "eis", and "cvct". Matching is case-insensitive,
%       surrounding whitespace is ignored, and a blank value means "auto".
%       Default: "auto".
%   opts - Optional scalar structure. Options apply to chrono loading only.
%
% Options:
%   pulseMode - Pulse-detection mode accepted by detectPulses, such as
%       "Metadata first, then auto", "Metadata only", or "Auto from Im only".
%   pulseOptions - Structure with a mode field accepted by detectPulses. When
%       both pulseOptions and pulseMode are present, pulseOptions takes
%       precedence.
%
% Outputs:
%   item - Scalar parsed item structure when status.ok is true, or an empty
%       structure array when loading fails. See Output Fields.
%   status - Scalar structure with ok, message, kind, expectedKind, and
%       filepath fields. A kind mismatch reports both the expected and detected
%       family in message.
%
% Output Fields:
%   type - "chrono", "eis", or "cvct".
%   filepath - Source path as a character vector.
%   name - Source filename including extension.
%   meta - Parsed metadata for chrono and EIS items.
%   tables - Parsed table structures for chrono and EIS items.
%   t_s - Chrono time in seconds.
%   Vf_V - Chrono measured voltage in volts.
%   Im_A - Chrono measured current in amperes.
%   pulse - Chrono pulse structure returned by detectPulses.
%   freq_Hz - EIS frequency in hertz.
%   Zreal_ohm - EIS real impedance in ohms.
%   Zimag_ohm - EIS imaginary impedance in ohms.
%   Zmod_ohm - EIS impedance magnitude in ohms.
%   Zphz_deg - EIS phase angle in degrees.
%   scanRate_V_per_s - CV/CT scan rate in volts per second.
%   curves - Parsed CV/CT curve structures in file order.
%   analysis - Empty structure reserved for caller-owned results.
%
% Errors:
%   Throws labkit:dta:InvalidFilepath for a nonscalar path and
%   labkit:dta:InvalidKind for an unsupported expectedKind. Missing files,
%   unsupported content, parse failures, and type mismatches are returned as
%   status.ok=false rather than thrown.
%
% Example:
%   [item, status] = labkit.dta.loadFile("measurement.DTA", "eis");
%   if status.ok
%       semilogx(item.freq_Hz, item.Zmod_ohm)
%   else
%       warning("%s", status.message)
%   end

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
