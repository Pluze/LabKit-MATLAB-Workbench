function T = buildCICResultsTable(items, unitLabel)
%BUILDCICRESULTSTABLE Build legacy CIC CSV result table.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitSuffix] = displayScale(unitLabel);

    file = cell(numel(items), 1);
    amp_A = NaN(numel(items), 1);
    Emc_V = NaN(numel(items), 1);
    Ema_V = NaN(numel(items), 1);
    Qc_C = NaN(numel(items), 1);
    Qa_C = NaN(numel(items), 1);
    Qt_C = NaN(numel(items), 1);
    CICc = NaN(numel(items), 1);
    CICa = NaN(numel(items), 1);
    CICt = NaN(numel(items), 1);
    safe = zeros(numel(items), 1);
    detection = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            detection{i} = 'failed';
            continue;
        end

        amp_A(i) = A.ampEstimate_A;
        Emc_V(i) = A.Emc;
        Ema_V(i) = A.Ema;
        Qc_C(i) = A.Qc_C;
        Qa_C(i) = A.Qa_C;
        Qt_C(i) = A.Qt_C;
        CICc(i) = scale * A.CICc_mCcm2;
        CICa(i) = scale * A.CICa_mCcm2;
        CICt(i) = scale * A.CICt_mCcm2;
        safe(i) = A.safe;
        detection{i} = A.detectMode;
    end

    T = table(file, amp_A, Emc_V, Ema_V, Qc_C, Qa_C, Qt_C, CICc, CICa, CICt, safe, detection, ...
        'VariableNames', {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        ['CICc_' unitSuffix], ['CICa_' unitSuffix], ['CICt_' unitSuffix], 'Safe', 'Detection'});
end

function [scale, unitSuffix] = displayScale(unitLabel)
    switch unitLabel
        case 'uC/cm^2'
            scale = 1e3;
            unitLabel = 'uC/cm^2';
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end
    unitSuffix = regexprep(unitLabel, '[\^/]', '');
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
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
