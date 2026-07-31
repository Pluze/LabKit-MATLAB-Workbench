% Expected caller: CSC app runner and export tests. Inputs are CV/CT item
% structs and CSC options. Output is one CSV-ready row per file curve/cycle
% with cathodic, anodic, and full CSC values. No file or UI side effects.

function T = buildResultsTable(items, opts)
%BUILDRESULTSTABLE Build CSC all-cycle export table.

    if nargin < 2
        opts = struct();
    end
    opts = fillOptions(opts);

    rows = collectRows(items, opts);
    if isempty(rows)
        rows = emptyRows();
    end
    T = struct2table(rows);
end

function rows = collectRows(items, opts)
    choices = csc.analysisRun.analysisChoices();
    capacity = sum(arrayfun(@(item) max(1, numel(itemCurves(item))), items));
    rowCells = cell(1, capacity);
    rowCount = 0;
    for iItem = 1:numel(items)
        item = items(iItem);
        curves = itemCurves(item);
        if isempty(curves)
            rowCount = rowCount + 1;
            rowCells{rowCount} = failedRow(item, 0, "", opts, "No curve found");
            continue;
        end
        curveIndices = selectedCurveIndices(numel(curves), opts);
        for iCurve = curveIndices
            curve = curves(iCurve);
            result = csc.analysisRun.computeCSC(curve, struct( ...
                'mode', char(choices.modes(1)), ...
                'scanRate', itemScanRate(item), ...
                'area_cm2', opts.area_cm2));
            rowCount = rowCount + 1;
            rowCells{rowCount} = resultRow(item, iCurve, curve, opts, result);
        end
    end
    rowCells = rowCells(1:rowCount);
    if isempty(rowCells)
        rows = emptyRows();
    else
        rows = vertcat(rowCells{:});
    end
end

function row = resultRow(item, curveIndex, curve, opts, result)
    row = failedRow(item, curveIndex, curveName(curve), opts, result.message);
    row.Rows = double(size(curve.data, 1));
    row.ScanRate_V_s = itemScanRate(item);
    if ~result.ok
        return;
    end

    row.Area_cm2 = result.area_cm2;
    row.QctCath_C = result.QctCath;
    row.QctAnod_C = result.QctAnod;
    row.QctFull_C = result.QctFull;
    row.QcvCath_C = result.QcvCath;
    row.QcvAnod_C = result.QcvAnod;
    row.QcvFull_C = result.QcvFull;
    row.DiffCath_C = result.QctCath - result.QcvCath;
    row.DiffAnod_C = result.QctAnod - result.QcvAnod;
    row.DiffFull_C = result.QctFull - result.QcvFull;
    row.RelativeDiffCath_pct = relativePct(row.DiffCath_C, result.QctCath, result.QcvCath);
    row.RelativeDiffAnod_pct = relativePct(row.DiffAnod_C, result.QctAnod, result.QcvAnod);
    row.RelativeDiffFull_pct = relativePct(row.DiffFull_C, result.QctFull, result.QcvFull);
    row.DtError_s = result.dtErr;
    row.CSCctCath_mCcm2 = normalizeCharge(result.QctCath, result.area_cm2);
    row.CSCctAnod_mCcm2 = normalizeCharge(result.QctAnod, result.area_cm2);
    row.CSCctFull_mCcm2 = normalizeCharge(result.QctFull, result.area_cm2);
    row.CSCcvCath_mCcm2 = normalizeCharge(result.QcvCath, result.area_cm2);
    row.CSCcvAnod_mCcm2 = normalizeCharge(result.QcvAnod, result.area_cm2);
    row.CSCcvFull_mCcm2 = normalizeCharge(result.QcvFull, result.area_cm2);
    row.Status = string(result.message);
end

function row = failedRow(item, curveIndex, curveNameText, opts, message)
    row = struct( ...
        'File', string(itemName(item)), ...
        'CurveIndex', double(curveIndex), ...
        'CurveName', string(curveNameText), ...
        'Rows', NaN, ...
        'ScanRate_V_s', itemScanRate(item), ...
        'Area_cm2', parsedArea(opts.area_cm2), ...
        'QctCath_C', NaN, ...
        'QctAnod_C', NaN, ...
        'QctFull_C', NaN, ...
        'QcvCath_C', NaN, ...
        'QcvAnod_C', NaN, ...
        'QcvFull_C', NaN, ...
        'DiffCath_C', NaN, ...
        'DiffAnod_C', NaN, ...
        'DiffFull_C', NaN, ...
        'RelativeDiffCath_pct', NaN, ...
        'RelativeDiffAnod_pct', NaN, ...
        'RelativeDiffFull_pct', NaN, ...
        'DtError_s', NaN, ...
        'CSCctCath_mCcm2', NaN, ...
        'CSCctAnod_mCcm2', NaN, ...
        'CSCctFull_mCcm2', NaN, ...
        'CSCcvCath_mCcm2', NaN, ...
        'CSCcvAnod_mCcm2', NaN, ...
        'CSCcvFull_mCcm2', NaN, ...
        'Status', string(message));
end

function rows = emptyRows()
    rows = repmat(failedRow(struct(), 0, "", struct('area_cm2', NaN), ""), 0, 1);
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
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

function curves = itemCurves(item)
    if isfield(item, 'curves')
        curves = item.curves;
    else
        curves = struct('name', {}, 'headers', {}, 'units', {}, ...
            'data', {}, 'numericMask', {});
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

function name = curveName(curve)
    if isfield(curve, 'name')
        name = curve.name;
    else
        name = "";
    end
end

function area = parsedArea(value)
    if isnumeric(value)
        area = value;
    else
        area = str2double(strtrim(char(value)));
    end
    if ~isscalar(area) || ~isfinite(area) || area <= 0
        area = NaN;
    end
end

function value = normalizeCharge(charge_C, area_cm2)
    value = csc.analysisRun.chargeDensity(charge_C, area_cm2);
end

function value = relativePct(diff_C, qct_C, qcv_C)
    denom = max(abs(qct_C), abs(qcv_C));
    if denom == 0
        value = 0;
    else
        value = 100 * abs(diff_C) / denom;
    end
end
