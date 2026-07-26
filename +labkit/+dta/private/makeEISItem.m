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
%   item - EIS item with parser outputs, zcurve, unit-explicit vectors,
%          frequency-order metadata, and analysis struct.
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
    item.point = defaultColumn(curve, 'Pt');
    item.time_s = defaultColumn(curve, 'Time');
    item.freq_Hz = defaultColumn(curve, 'Freq');
    item.Zreal_ohm = defaultColumn(curve, 'Zreal');
    item.Zimag_ohm = defaultColumn(curve, 'Zimag');
    item.negZimag_ohm = -item.Zimag_ohm;
    item.Zmod_ohm = defaultColumn(curve, 'Zmod');
    item.Zphz_deg = defaultColumn(curve, 'Zphz');
    item.Idc_A = defaultColumn(curve, 'Idc');
    item.Vdc_V = defaultColumn(curve, 'Vdc');

    valid = isfinite(item.freq_Hz) | isfinite(item.Zreal_ohm) | ...
        isfinite(item.Zimag_ohm) | isfinite(item.Zmod_ohm) | ...
        isfinite(item.Zphz_deg);
    fields = {'point', 'time_s', 'freq_Hz', 'Zreal_ohm', ...
        'Zimag_ohm', 'negZimag_ohm', 'Zmod_ohm', 'Zphz_deg', ...
        'Idc_A', 'Vdc_V'};
    for ii = 1:numel(fields)
        item.(fields{ii}) = item.(fields{ii})(valid);
    end

    if numel(item.point) < 2
        error('Not enough valid ZCURVE points.');
    end

    if isempty(item.point) || all(~isfinite(item.point))
        item.point = (0:numel(item.freq_Hz)-1).';
    end

    item.n = numel(item.point);
    item.freqDesc = isMostlyDescending(item.freq_Hz);
    item.message = msg;
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
