function item = makeChronoItem(filepath, opts)
%MAKECHRONOITEM Load a chrono DTA file into a package-backed item struct.

    if nargin < 2
        opts = struct();
    end

    item = struct();
    item.type = "chrono";
    item.filepath = filepath;
    item.name = shortName(filepath);
    [item.meta, item.tables, item.logmsg] = gamrywb.io.parseChronoDTA(filepath);

    [curve, ok, msg] = gamrywb.data.getMainCurve(item.tables);
    if ~ok
        error('%s', msg);
    end

    t = gamrywb.data.getColumn(curve, 'T');
    Vf = gamrywb.data.getColumn(curve, 'Vf');
    Im = gamrywb.data.getColumn(curve, 'Im');
    pt = gamrywb.data.getColumn(curve, 'Pt');
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

    % Legacy field names are kept until all GUI call sites migrate.
    item.t = t(:);
    item.Vf = Vf(:);
    item.Im = Im(:);
    item.pt = pt(:);
    item.n = numel(t);
    item.message = msg;

    % Unit-explicit package field names are the long-term data model.
    item.t_s = item.t;
    item.Vf_V = item.Vf;
    item.Im_A = item.Im;
    item.alignTime = NaN;
    item.tAligned = [];
    item.alignTime_s = NaN;
    item.tAligned_s = [];
    item.analysis = struct();

    if isfield(opts, 'pulseOptions')
        pulseOptions = opts.pulseOptions;
    elseif isfield(opts, 'pulseMode')
        pulseOptions = struct('mode', opts.pulseMode);
    else
        pulseOptions = gamrywb.analysis.defaultPulseOptions();
    end

    [item.pulse, pulseMsg] = gamrywb.analysis.detectPulses(item.t, item.Im, item.meta, pulseOptions);
    item.pulseMessage = pulseMsg;
end

function name = shortName(filepath)
    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end
