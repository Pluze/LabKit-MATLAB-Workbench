function T = buildResultsTable(items)
%BUILDRESULTSTABLE Build a CSC app result table.

    file = cell(numel(items), 1);
    curve = cell(numel(items), 1);
    mode = cell(numel(items), 1);
    scanRate_V_s = NaN(numel(items), 1);
    area_cm2 = NaN(numel(items), 1);
    Qct_C = NaN(numel(items), 1);
    Qcv_C = NaN(numel(items), 1);
    diff_C = NaN(numel(items), 1);
    rel_pct = NaN(numel(items), 1);
    dtErr_s = NaN(numel(items), 1);
    Qct_mC_cm2 = NaN(numel(items), 1);
    Qcv_mC_cm2 = NaN(numel(items), 1);
    diff_mC_cm2 = NaN(numel(items), 1);
    status = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        curve{i} = curveName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            mode{i} = '';
            status{i} = analysisMessage(A);
            continue;
        end

        mode{i} = A.mode;
        scanRate_V_s(i) = A.scanRate;
        area_cm2(i) = A.area_cm2;
        Qct_C(i) = A.Qct;
        Qcv_C(i) = A.Qcv;
        diff_C(i) = A.diff_C;
        rel_pct(i) = A.rel_pct;
        dtErr_s(i) = A.dtErr;
        Qct_mC_cm2(i) = A.Qct_mC_cm2;
        Qcv_mC_cm2(i) = A.Qcv_mC_cm2;
        diff_mC_cm2(i) = A.diff_mC_cm2;
        status{i} = A.message;
    end

    T = table(file, curve, mode, scanRate_V_s, area_cm2, Qct_C, Qcv_C, ...
        diff_C, rel_pct, dtErr_s, Qct_mC_cm2, Qcv_mC_cm2, diff_mC_cm2, status, ...
        'VariableNames', {'File', 'Curve', 'Mode', 'ScanRate_V_s', 'Area_cm2', ...
        'Qct_C', 'Qcv_C', 'Diff_C', 'RelDiff_pct', 'DtErr_s', ...
        'Qct_mC_cm2', 'Qcv_mC_cm2', 'Diff_mC_cm2', 'Status'});
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    elseif isfield(item, 'filepath')
        name = gamrywb.util.shortName(item.filepath);
    else
        name = '';
    end
end

function name = curveName(item)
    if isfield(item, 'curveName')
        name = item.curveName;
    elseif isfield(item, 'curve') && isfield(item.curve, 'name')
        name = item.curve.name;
    else
        name = '';
    end
end

function A = itemAnalysis(item)
    if isfield(item, 'analysis')
        A = item.analysis;
    else
        A = [];
    end
end

function msg = analysisMessage(A)
    msg = '';
    if ~isempty(A) && isfield(A, 'message')
        msg = A.message;
    end
end
