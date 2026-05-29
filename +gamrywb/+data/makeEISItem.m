function item = makeEISItem(filepath)
%MAKEEISITEM Build a legacy-compatible EIS item from a Gamry DTA file.

    item = struct();
    item.filepath = filepath;
    item.name = gamrywb.util.shortName(filepath);
    [item.meta, item.tables, item.logmsg] = gamrywb.io.parseEISDTA(filepath);

    [curve, ok, msg] = gamrywb.data.getZCurve(item.tables);
    if ~ok
        error('%s', msg);
    end

    item.curve = curve;
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
end

function col = defaultColumn(tbl, name)
    col = gamrywb.data.getColumn(tbl, name);
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
