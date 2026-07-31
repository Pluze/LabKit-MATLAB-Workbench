% Expected caller: CSC app runner and export tests. Inputs are CV/CT item
% structs, a target CSV path, and export options. Side effect is writing
% column-oriented CV data: one voltage column and current/scan-rate columns for
% each exported file cycle. If voltage vectors differ across DTA files, one CSV
% is written per DTA item.

function [ok, msg, info] = writeVoltageCurrentCSV(items, filepath, opts)
%WRITEVOLTAGECURRENTCSV Export column-oriented CSC CV data.

    if nargin < 3
        opts = struct();
    end

    ok = true;
    msg = '';
    info = struct('files', string.empty(0, 1), 'rows', 0);

    try
        records = collectRecords(items, opts);
        if isempty(records)
            error('csc:resultFiles:NoVoltageCurrentData', ...
                'No voltage/current data to export.');
        end

        if recordsShareVoltage(records)
            C = recordsToCell(records);
            writecell(C, filepath);
            info.files = string(filepath);
            info.rows = size(C, 1) - 1;
            return;
        end

        outputs = itemOutputs(records, filepath);
        written = strings(numel(outputs), 1);
        totalRows = 0;
        for k = 1:numel(outputs)
            C = recordsToCell(outputs(k).records);
            writecell(C, outputs(k).filepath);
            written(k) = string(outputs(k).filepath);
            totalRows = totalRows + size(C, 1) - 1;
        end
        info.files = written;
        info.rows = totalRows;
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

function records = collectRecords(items, opts)
    opts = fillOptions(opts);
    capacity = sum(arrayfun(@(item) ...
        double(isfield(item, 'curves')) * numel(itemCurvesForCapacity(item)), items));
    recordCells = cell(1, capacity);
    recordCount = 0;
    for iItem = 1:numel(items)
        item = items(iItem);
        if ~isfield(item, 'curves') || isempty(item.curves)
            continue;
        end
        indices = selectedCurveIndices(numel(item.curves), opts);
        for iCurve = indices
            record = curveRecord(item, iItem, iCurve);
            if record.ok
                recordCount = recordCount + 1;
                recordCells{recordCount} = rmfield(record, 'ok');
            end
        end
    end
    recordCells = recordCells(1:recordCount);
    if isempty(recordCells)
        records = struct([]);
    else
        records = vertcat(recordCells{:});
    end
end

function curves = itemCurvesForCapacity(item)
    curves = struct([]);
    if isfield(item, 'curves')
        curves = item.curves;
    end
end

function record = curveRecord(item, itemIndex, curveIndex)
    curve = item.curves(curveIndex);
    voltage = exactColumn(curve, 'Vf');
    current = exactColumn(curve, 'Im');
    good = ~(isnan(voltage) | isnan(current));
    voltage = voltage(good);
    current = current(good);
    record = struct('ok', ~isempty(voltage) && ~isempty(current), ...
        'itemIndex', double(itemIndex), ...
        'itemName', string(itemName(item)), ...
        'curveIndex', double(curveIndex), ...
        'scanRate', itemScanRate(item), ...
        'voltage', voltage(:), ...
        'current', current(:));
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

function tf = recordsShareVoltage(records)
    tf = true;
    if isempty(records)
        return;
    end
    base = records(1).voltage;
    for k = 2:numel(records)
        candidate = records(k).voltage;
        if numel(candidate) ~= numel(base) || any(candidate ~= base)
            tf = false;
            return;
        end
    end
end

function C = recordsToCell(records)
    voltage = voltageGrid(records);
    C = cell(numel(voltage) + 1, numel(records) * 2 + 1);
    C{1, 1} = 'Potential_V';
    C(2:end, 1) = num2cell(voltage);
    for k = 1:numel(records)
        currentCol = (k - 1) * 2 + 2;
        scanRateCol = currentCol + 1;
        C{1, currentCol} = currentColumnName(records(k));
        C{1, scanRateCol} = scanRateColumnName(records(k));
        C(2:end, currentCol) = currentValuesOnGrid(voltage, records(k));
        C(2:end, scanRateCol) = num2cell(repmat(records(k).scanRate, ...
            numel(voltage), 1));
    end
end

function values = voltageGrid(records)
    cells = arrayfun(@(record) record.voltage(:), records, ...
        'UniformOutput', false);
    values = unique(vertcat(cells{:}), 'sorted');
end

function values = currentValuesOnGrid(voltageGridValues, record)
    values = cell(numel(voltageGridValues), 1);
    [tf, loc] = ismember(record.voltage, voltageGridValues);
    for k = find(tf).'
        values{loc(k)} = record.current(k);
    end
end

function outputs = itemOutputs(records, filepath)
    [folder, stem, ext] = fileparts(filepath);
    if strlength(string(ext)) == 0
        ext = '.csv';
    end
    itemIndices = unique([records.itemIndex], 'stable');
    outputs = repmat(struct('filepath', "", 'records', records([])), ...
        1, numel(itemIndices));
    for k = 1:numel(itemIndices)
        itemRecords = records([records.itemIndex] == itemIndices(k));
        outputs(k).filepath = fullfile(folder, sprintf('%s_%s%s', ...
            stem, safeStem(itemRecords(1).itemName), ext));
        outputs(k).records = itemRecords;
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

function text = currentColumnName(record)
    text = sprintf('%s_Cycle%d_Current_A', ...
        safeStem(record.itemName), record.curveIndex);
end

function text = scanRateColumnName(record)
    text = sprintf('%s_Cycle%d_ScanRate_V_s', ...
        safeStem(record.itemName), record.curveIndex);
end

function stem = safeStem(value)
    stem = regexprep(char(string(value)), '[^A-Za-z0-9_-]+', '_');
    stem = regexprep(stem, '^_+|_+$', '');
    if isempty(stem)
        stem = 'item';
    end
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
