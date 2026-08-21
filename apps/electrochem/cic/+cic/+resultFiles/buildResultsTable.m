% Expected caller: CIC app runner and export tests. Inputs are item structs and
% display unit label. Output is the stable CIC CSV result table. No file side
% effects.

function T = buildResultsTable(items, unitLabel)
%BUILDRESULTSTABLE Build the CIC CSV result table.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitSuffix] = displayScaleSuffix(unitLabel);

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
    area_cm2 = NaN(numel(items), 1);
    delay_us = NaN(numel(items), 1);

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
        area_cm2(i) = A.area_cm2;
        % Constant: one million converts seconds to microseconds for export.
        microsecondsPerSecond = 1e6;
        delay_us(i) = microsecondsPerSecond * A.delay_s;
    end

    T = table(file, amp_A, Emc_V, Ema_V, Qc_C, Qa_C, Qt_C, CICc, CICa, CICt, ...
        safe, detection, area_cm2, delay_us, ...
        'VariableNames', {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        ['CICc_' unitSuffix], ['CICa_' unitSuffix], ['CICt_' unitSuffix], ...
        'Safe', 'Detection', 'Area_cm2', 'Delay_us'});
end

function [scale, unitSuffix] = displayScaleSuffix(unitLabel)
    [scale, unitLabel] = displayScale(unitLabel);
    unitSuffix = regexprep(unitLabel, '[\^/]', '');
end

function [scale, unitLabel] = displayScale(unitLabel)
    [scale, unitLabel] = cic.analysisRun.displayUnit(unitLabel);
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
