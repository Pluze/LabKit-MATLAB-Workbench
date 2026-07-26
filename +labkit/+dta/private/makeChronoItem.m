% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function item = makeChronoItem(filepath, opts)
%MAKECHRONOITEM Load a chrono DTA file into a DTA item struct.
%
% Called by:
%   labkit.dta.loadFile when detected/expected kind is "chrono".
%
% Inputs:
%   filepath - Gamry chrono DTA file path.
%   opts - optional pulse-detection options forwarded to detectPulseCore.
%
% Output:
%   item - chrono item with parser outputs, unit-explicit arrays, pulse info,
%          alignment fields, message, and analysis struct.
%
% Errors:
%   Throws when the main curve is missing or fewer than two valid T/Vf/Im
%   samples remain after filtering.

    if nargin < 2
        opts = struct();
    end

    item = struct();
    item.type = "chrono";
    item.filepath = filepath;
    item.name = shortName(filepath);
    [item.meta, item.tables, item.logmsg] = parseChronoDTA(filepath);
    item.controlMode = item.meta.controlMode;

    [curve, ok, msg] = labkit.dta.getMainCurve(item.tables);
    if ~ok
        error('%s', msg);
    end

    t = labkit.dta.getColumn(curve, 'T');
    Vf = labkit.dta.getColumn(curve, 'Vf');
    Im = labkit.dta.getColumn(curve, 'Im');
    pt = labkit.dta.getColumn(curve, 'Pt');
    if isempty(pt)
        pt = (0:numel(t)-1).';
    end

    valid = isfinite(t) & isfinite(Vf) & isfinite(Im);
    t = t(valid);
    Vf = Vf(valid);
    Im = Im(valid);
    pt = pt(valid);

    if numel(t) < 2
        error('Not enough valid T/Vf/Im data points.');
    end

    [t, ia] = unique(t, 'stable');
    Vf = Vf(ia);
    Im = Im(ia);
    pt = pt(ia);

    item.curve = curve;

    item.t_s = t(:);
    item.Vf_V = Vf(:);
    item.Im_A = Im(:);
    item.pt = pt(:);
    item.n = numel(t);
    item.message = msg;
    item.alignTime_s = NaN;
    item.tAligned_s = [];
    item.analysis = struct();

    if isfield(opts, 'pulseOptions')
        [item.pulse, pulseMsg] = detectPulseCore( ...
            item.t_s, item.Im_A, item.meta, opts.pulseOptions);
    elseif isfield(opts, 'pulseMode')
        [item.pulse, pulseMsg] = detectPulseCore( ...
            item.t_s, item.Im_A, item.meta, opts.pulseMode);
    else
        [item.pulse, pulseMsg] = detectPulseCore( ...
            item.t_s, item.Im_A, item.meta);
    end
    item.pulseMessage = pulseMsg;
end

function name = shortName(filepath)
    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end
