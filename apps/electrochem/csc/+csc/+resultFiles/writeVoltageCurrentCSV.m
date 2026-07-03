% Expected caller: CSC app runner and export tests. Inputs are CV/CT item
% structs, a target CSV path, and export options. Side effect is writing one
% point-level CSV for plotting CV curves and recalculating CSC.

function [ok, msg, info] = writeVoltageCurrentCSV(items, filepath, opts)
%WRITEVOLTAGECURRENTCSV Export point-level CSC voltage/current data.

    if nargin < 3
        opts = struct();
    end

    ok = true;
    msg = '';
    info = struct('files', string.empty(0, 1), 'rows', 0);

    try
        T = buildVoltageCurrentTable(items, opts);
        if height(T) == 0
            error('csc:resultFiles:NoVoltageCurrentData', ...
                'No voltage/current data to export.');
        end
        writetable(T, filepath);
        info.files = string(filepath);
        info.rows = height(T);
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

function T = buildVoltageCurrentTable(items, opts)
    opts = fillOptions(opts);
    tables = {};
    for iItem = 1:numel(items)
        item = items(iItem);
        if ~isfield(item, 'curves') || isempty(item.curves)
            continue;
        end
        included = selectedCurveIndices(numel(item.curves), opts);
        for iCurve = 1:numel(item.curves)
            Tcurve = curveTable(item, iCurve, ismember(iCurve, included));
            if ~isempty(Tcurve)
                tables{end + 1} = Tcurve;
            end
        end
    end
    if isempty(tables)
        T = emptyTable();
    else
        T = vertcat(tables{:});
    end
end

function T = curveTable(item, curveIndex, included)
    curve = item.curves(curveIndex);
    [t, v, i] = curveTVI(curve);
    good = ~(isnan(t) | isnan(v) | isnan(i));
    t = t(good);
    v = v(good);
    i = i(good);
    if isempty(t)
        T = table();
        return;
    end

    n = numel(t);
    T = table();
    T.File = repmat(string(itemName(item)), n, 1);
    T.CycleIndex = repmat(double(curveIndex), n, 1);
    T.PointIndex = (1:n).';
    T.Potential_V = v(:);
    T.Current_A = i(:);
    T.ScanRate_V_s = repmat(itemScanRate(item), n, 1);
    T.IncludeInCSC = repmat(logical(included), n, 1);
end

function [t, v, i] = curveTVI(curve)
    t = exactColumn(curve, 'T');
    v = exactColumn(curve, 'Vf');
    i = exactColumn(curve, 'Im');
end

function values = exactColumn(curve, name)
    values = [];
    if ~isfield(curve, 'headers') || ~isfield(curve, 'data')
        return;
    end
    idx = find(strcmp(curve.headers, name), 1);
    if ~isempty(idx)
        values = curve.data(:, idx);
    end
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'ignoreEdgeCycles')
        opts.ignoreEdgeCycles = false;
    end
end

function indices = selectedCurveIndices(count, opts)
    indices = 1:count;
    if logicalScalar(opts.ignoreEdgeCycles) && count > 0
        indices = indices(indices ~= 1 & indices ~= count);
    end
end

function tf = logicalScalar(value)
    if islogical(value) || isnumeric(value)
        tf = isscalar(value) && logical(value);
    else
        tf = any(strcmpi(string(value), ["true", "on", "1", "yes"]));
    end
end

function T = emptyTable()
    T = table(strings(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), false(0, 1), ...
        'VariableNames', {'File', 'CycleIndex', 'PointIndex', ...
        'Potential_V', 'Current_A', 'ScanRate_V_s', 'IncludeInCSC'});
end

function value = itemScanRate(item)
    if isfield(item, 'scanRate')
        value = item.scanRate;
    elseif isfield(item, 'scanRate_V_per_s')
        value = item.scanRate_V_per_s;
    else
        value = NaN;
    end
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    elseif isfield(item, 'filepath')
        [~, name, ext] = fileparts(item.filepath);
        name = [name ext];
    else
        name = "";
    end
end
