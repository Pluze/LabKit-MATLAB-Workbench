% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function item = makeEISItem(filepath)
%MAKEEISITEM Build an EIS DTA item struct from a Gamry DTA file.
%
% Called by:
%   labkit.dta.loadFile when detected/expected kind is "eis".
%
% Inputs:
%   filepath - Gamry EIS DTA file path containing a ZCURVE table.
%
% Output:
%   item - EIS item with parser outputs, zcurve, normalized field aliases,
%          legacy bridge fields, frequency-order metadata, and analysis struct.
%
% Errors:
%   Throws when no usable ZCURVE data remains.

    item = struct();
    item.type = "eis";
    item.filepath = filepath;
    item.name = shortName(filepath);
    [item.meta, item.tables, item.logmsg] = parseEISDTA(filepath);

    [curve, ok, msg] = labkit.dta.getZCurve(item.tables);
    if ~ok
        error('%s', msg);
    end

    item.curve = curve;
    item.zcurve = curve;
    item.Pt = defaultColumn(curve, 'Pt');
    item.Time = defaultColumn(curve, 'Time');
    item.Freq = defaultColumn(curve, 'Freq');
    item.Zreal = defaultColumn(curve, 'Zreal');
    item.Zimag = defaultColumn(curve, 'Zimag');
    item.Zmod = defaultColumn(curve, 'Zmod');
    item.Zphz = defaultColumn(curve, 'Zphz');
    item.Idc = defaultColumn(curve, 'Idc');
    item.Vdc = defaultColumn(curve, 'Vdc');
    item.negZimag = -item.Zimag;

    valid = isfinite(item.Freq) | isfinite(item.Zreal) | isfinite(item.Zimag) ...
        | isfinite(item.Zmod) | isfinite(item.Zphz);
    fields = {'Pt', 'Time', 'Freq', 'Zreal', 'Zimag', 'negZimag', 'Zmod', 'Zphz', 'Idc', 'Vdc'};
    for ii = 1:numel(fields)
        item.(fields{ii}) = item.(fields{ii})(valid);
    end

    if numel(item.Pt) < 2
        error('Not enough valid ZCURVE points.');
    end

    if isempty(item.Pt) || all(~isfinite(item.Pt))
        item.Pt = (0:numel(item.Freq)-1).';
    end

    item.n = numel(item.Pt);
    item.freqDesc = isMostlyDescending(item.Freq);
    item.message = msg;

    % Unit-explicit aliases are the long-term data model; legacy fields stay
    % for behavior-preserving GUI compatibility.
    item.point = item.Pt;
    item.time_s = item.Time;
    item.freq_Hz = item.Freq;
    item.Zreal_ohm = item.Zreal;
    item.Zimag_ohm = item.Zimag;
    item.negZimag_ohm = item.negZimag;
    item.Zmod_ohm = item.Zmod;
    item.Zphz_deg = item.Zphz;
    item.Idc_A = item.Idc;
    item.Vdc_V = item.Vdc;
    item.analysis = struct();
end

function col = defaultColumn(tbl, name)
    col = labkit.dta.getColumn(tbl, name);
    if isempty(col)
        col = NaN(size(tbl.data, 1), 1);
    end
    col = col(:);
end

function tf = isMostlyDescending(x)
    x = x(isfinite(x));
    if numel(x) < 2
        tf = false;
        return;
    end
    dx = diff(x);
    tf = sum(dx < 0) >= sum(dx > 0);
end

function name = shortName(filepath)
    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end
